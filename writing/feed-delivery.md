# Public feed delivery

Robin Winters's existing technical-writing feeds advertise their canonical self URL and Google PubSubHubbub at https://pubsubhubbub.appspot.com/. Compatible readers can request update subscriptions through the hub. Ordinary feed polling remains available. The hub documents legacy PubSubHubbub 0.4 support. A standards-conformance test confirmed an active subscription on October 4, 2026; notification delivery was not observed. Hub acknowledgement alone does not prove a successful fetch, notification delivery, search indexing or ranking improvement.

## Canonical topics

- Full RSS: https://robinwinters.github.io/feed.xml
- Full Atom: https://robinwinters.github.io/feed.atom
- Native iOS: https://robinwinters.github.io/feeds/ios.xml
- Applied AI: https://robinwinters.github.io/feeds/applied-ai.xml
- Fitness technology: https://robinwinters.github.io/feeds/fitness-tech.xml

The JSON Feed remains available at https://robinwinters.github.io/feed.json; no unverified hub transport is advertised for that representation. GitHub source copies of RSS and Atom retain the deployed feed's canonical self URL, so subscriptions refer to the canonical topic rather than creating mirror subscriptions.

## Publish after a real update

After the changed feed is deployed and verified, send one form-encoded POST to the advertised hub with `hub.mode=publish` and `hub.url` equal to the changed canonical feed URL. The Google hub documents repeated `hub.url` fields for a batch. Do not ping unchanged topics on a schedule. Inspect publisher diagnostics to distinguish acknowledgement from a successful fetch; subscriber delivery remains separate. A conformance-test callback is not a real audience member and is not counted as readership.

A second hub was evaluated but removed after it returned HTTP 401 for all five publish requests and HTTP 404 for the subscription test. No working secondary delivery route is claimed.

References: [W3C WebSub](https://www.w3.org/TR/websub/), [the Google hub's publisher instructions](https://pubsubhubbub.appspot.com/) and [the W3C-linked publisher conformance test](https://websub.rocks/publisher).
