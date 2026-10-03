# Building an iOS Moderation Layer with Apple Foundation Models framework and Firebase

By Robin Winters · First published April 2, 2026 · Republished October 2, 2026

[Original LinkedIn edition](https://www.linkedin.com/pulse/building-ios-moderation-layer-apple-foundation-models-robin-winters-ejl5f/) · [Readable HTML edition](https://robinwinters.github.io/writing/moderation.html) · [Robin’s portfolio](https://robin.ac/)

Original wording, images and captions. Technical observations and opinions retain their original context.

![Painting of a man pinning a printed document to a door while two onlookers stand beside him.](images/moderation-2.png)


"YOU KNOW MARTIN THAT IT'S JUST GOING TO BE TAKEN DOWN AND YOU'LL BE BLOCKED FROM POSTING FOR THE NEXT 30 DAYS"



When building out a moderation layer in the Apple ecosystem we have a LOT of tools and guidance to help the process along so we as developers can make something both delightful and safe for the wide range of users we hope to reach.







I build iOS native products in Swift and SwiftUI, so I care a lot about how a system behaves in hand. I also care about whether it holds up once users start poking at it in weird ways. Moderation is where those things meetup. A bad classifier or a vague rejection banner is a product bug, but users experience both as the same thing.







Below is how I've been going about building a new-ish moderation layer for iOS that can be applied basically anywhere it's needed with a few caveats.







After messing about with a number of increasingly elaborate designs, I landed on a hybrid architecture where each side does a different job quite well:







- Apple’s [Foundation Models framework](https://developer.apple.com/apple-intelligence/whats-new/) gives fast, private, on-device text classification and rewrite suggestions.
- [Firebase callable functions](https://firebase.google.com/docs/functions/callable) for server authoritative decision paths with Auth, App Check, audit logs, and review hooks.
- Cloud Storage triggers for handling media separately, because images and video are their own special form of pain.







**Caveat:** The main constraint with Apple’s model is that it only runs on Apple Intelligence capable devices in supported regions and Apple explicitly tells developers to check availability before building around it. Their own guidance also says to make sure the experience still works when generative features aren’t available. I definitely don't want moderation to disappear because a user has an unsupported device, region, or language setup, but this should solve itself with time and broader adoption of more modern devices.







Sauce: [WWDC25 Foundation Models](https://developer.apple.com/videos/play/wwdc2025/286/), [SystemLanguageModel availability](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum), [Generative AI HIG](https://developer.apple.com/design/human-interface-guidelines/generative-ai)







Here’s a fun little diagram for flowchart fans:









 ![Moderation architecture diagram: a SwiftUI composer sends text through on-device Apple Foundation Models preflight to Firebase Functions. Decision, trust and rules layers support publishing, blocking or editing, visibility limits and human review. Cloud uploads have a separate media-moderation path, with appeals and client-state feedback.](images/moderation-1.png)


Fun is a relative term.







On the client side I’m using Apple’s model for text-only moderation signals before the content ever leaves the device. That gives me two preem properties right away. First, it's fast. Second, I can warn a user about obvious problems without dumping every draft to the backend.







Apple’s Foundation Models framework is a good fit for this b/c Apple positions it for tasks like extraction, summarization, and classification. Exactly the kind of narrow job I want on device.







Sauce: [What’s New in Apple Intelligence](https://developer.apple.com/apple-intelligence/whats-new/)







The Swift side looks roughly like this:







```
import FoundationModels

@Generable
struct ModerationSignal {
    @Guide(description: "One of: safe, harassment, self_harm, doxxing, spam, sexual_content, review")
    var label: String

    @Guide(description: "Confidence score from 0 to 100")
    var confidence: Int

    @Guide(description: "True if the text appears to include personal contact information")
    var containsPII: Bool

    @Guide(description: "Short user-facing suggestion if the content should be revised")
    var userMessage: String
}

@MainActor
func classifyDraft(_ text: String) async throws -> ModerationSignal? {
    let model = SystemLanguageModel.default
    guard case .available = model.availability else {
        return nil
    }

    let session = LanguageModelSession()
    let response = try await session.respond(
        to: "Classify this user-generated text for moderation: \(text)",
        generating: ModerationSignal.self
    )

    return response.content
}
```







A couple of things I dig about this. The response is structured so I’m not parsing model soup. The feature is private by default, and when the model is unavailable the app still works. It just skips the preflight hint and sends the content to the server.







Apple’s model is great when it's there but I am not building a moderation system that only works for the best case device matrix. Once the user submits content, Firebase takes over. I’m using a callable function so the app sends the content, the local moderation signal if one exists, and the user’s auth context through a standard path. Firebase’s docs call out a useful detail here: callable functions automatically include Auth and App Check tokens when available, and App Check enforcement can be turned on serverside.







Sauce: [Callable functions](https://firebase.google.com/docs/functions/callable), [App Check for Cloud Functions](https://firebase.google.com/docs/app-check/cloud-functions)







The server side looks more like infrastructure now. Cool beans.







```
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();

export const submitContent = onCall(
  { region: "us-central1", enforceAppCheck: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required");
    }

    const { body, localSignal } = request.data as {
      body: string;
      localSignal?: {
        label?: string;
        confidence?: number;
        containsPII?: boolean;
      };
    };

    const piiHit = /\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b/.test(body);
    const urlCount = (body.match(/https?:\/\//g) ?? []).length;
    const likelySpam = urlCount > 2;

    let action: "publish" | "review" | "block" = "publish";
    let reason: string | null = null;

    if (piiHit || localSignal?.containsPII) {
      action = "block";
      reason = "possible_pii";
    } else if (likelySpam || localSignal?.label === "review") {
      action = "review";
      reason = "needs_review";
    }

    const ref = await db.collection("content").add({
      uid: request.auth.uid,
      body,
      localSignal: localSignal ?? null,
      action,
      reason,
      createdAt: Date.now(),
    });

    return { id: ref.id, action, reason };
  }
);
```







This is where we get consistency. I can layer the review workflows around the model output instead of the model owning everything. I can also log the actual reason for a decision for later when somebody appeals or there's some over-moderation. Also, text and images fail in different ways. A Cloud Storage triggered function can pull the asset, hash it, run the heavier checks, and then write back a moderation state without blocking the client on every large upload. Firebase pushes Storage triggered processing as a standard use case.







Sauce: [Cloud Functions use cases](https://firebase.google.com/docs/functions/use-cases)







A few outside examples:







Reddit is a good example. It shows what "mature" moderation starts to look like over time. They have [AutoModerator](https://support.reddithelp.com/hc/en-us/articles/15484574206484-Automoderator), [Safety Filters](https://support.reddithelp.com/hc/en-us/articles/15484574845460-Safety-Filters), and a [moderation queue](https://support.reddithelp.com/hc/en-us/articles/15484440494356-Moderation-Queue). They also have a documented flow for [abuse of the report system](https://support.reddithelp.com/hc/en-us/articles/213099246-How-do-I-report-abuse-of-the-report-system).







The Meta example is the [breast cancer awareness case from the Oversight Board](https://www.oversightboard.com/decision/bun-0w49p93l/). Automated nudity enforcement caught legitimate health content. If the moderation stack sees skin and loses its mind, the product starts punishing the people it is supposed to help.







So the build has to stay narrow where it makes sense. On device Foundation Models for fast text preflight, Firebase Functions for final action, hard rules for obvious stuff, review queues for the ugly middle. Fallbacks for unsupported devices, and state driven UI so the user knows what happened.







Hopefully that made sense! Obviously this is just experimenting for now, but I think it's a good way to start thinking about how to layer moderation into whatever your building with Apple's Foundation Model framework.







Be excellent to each other,







🤘Robin
