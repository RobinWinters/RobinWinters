# Public feed delivery

Robin Winters's existing technical-writing feeds advertise both a canonical self URL and two hubs: Google PubSubHubbub at https://pubsubhubbub.appspot.com/ and Switchboard at https://switchboard.p3k.io/. Compatible readers can subscribe through that hub to receive updates. Ordinary feed polling remains available. The hub documents legacy PubSubHubbub 0.4 support; registration alone is not proof of an active subscriber, delivered notification, search indexing or ranking improvement.

## Canonical topics

- Full RSS: https://robinwinters.github.io/feed.xml
- Full Atom: https://robinwinters.github.io/feed.atom
- Native iOS: https://robinwinters.github.io/feeds/ios.xml
- Applied AI: https://robinwinters.github.io/feeds/applied-ai.xml
- Fitness technology: https://robinwinters.github.io/feeds/fitness-tech.xml

The JSON Feed remains available at https://robinwinters.github.io/feed.json; no unverified hub transport is advertised for that representation. GitHub source copies of RSS and Atom retain the deployed feed's canonical self URL, so subscriptions refer to the canonical topic rather than creating mirror subscriptions.

## Publish after a real update

After the changed feed is deployed and verified, send one form-encoded POST to each advertised hub with `hub.mode=publish` and `hub.url` equal to the changed canonical feed URL. The Google hub documents repeated `hub.url` fields for a batch; Switchboard documents one `hub.url` per request. Do not ping unchanged topics on a schedule. Inspect the hub's publisher diagnostics to distinguish acknowledgement from a successful fetch; subscriber delivery remains separate. No callback service, subscribers or notifications are manufactured for this record.

References: [W3C WebSub](https://www.w3.org/TR/websub/) and [the Google hub's publisher instructions](https://pubsubhubbub.appspot.com/) and [Switchboard's publishing instructions](https://switchboard.p3k.io/docs).
