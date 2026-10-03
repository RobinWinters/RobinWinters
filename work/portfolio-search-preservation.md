# Improving a personal portfolio's discoverability while preserving its interface

Robin Winters · October 2, 2026 · Personal website maintenance account

The requirement for [robin.ac](https://robin.ac/) was precise: preserve its existing phone-like interface, artwork, typography, visible text, animation, navigation and interactions. Improve the professional identity information that search systems can retrieve without redesigning the portfolio.

## Recover the deployed source before changing it

The production repository was recovered and compared with deployed HTML, CSS paths and image assets. Existing visible content was already present in initial HTML. There was no need to rebuild the rendering approach or insert additional text into the interface.

The changes were restricted to page metadata, a canonical URL, social previews using the existing portrait, a small Person JSON-LD record, robots rules, a one-URL sitemap and search ownership tags. The Person record identifies Robin Winters and links the confirmed GitHub and LinkedIn profiles. It does not contain an expanded hidden resume or unresolved credentials.

Google's [structured-data policies](https://developers.google.com/search/docs/appearance/structured-data/sd-policies) require markup to represent the page accurately. That principle set the boundary: richer professional explanations belong in public project documentation, while the homepage's structured identity describes what its existing content supports.

## Preserve behavior as well as pixels

Desktop captures at 1440 by 1000 and mobile captures at 390 by 844 were compared. The application page, styles and image assets remained unchanged. The live body matched the original recovered page. Clock values and native audio loading indicators varied between captures, so a perfect screenshot hash was not a meaningful acceptance test.

Existing work and notes panels, phone controls and skill interactions were checked before and after. These checks support preservation of the tested interface. They do not claim exhaustive browser compatibility or automated coverage of every possible interaction.

## Separate deployment from indexing

The final deployment was ready in Vercel, and the production domain served the verification tags. Google Search Console and Bing Webmaster Tools processed the sitemap successfully, each discovering the existing homepage URL.

Google's October 2 crawled HTML contains the new Person JSON-LD. Its selected canonical matches the inspected homepage. The latest shortened description was not yet confirmed in that indexed copy. Bing's live test said the URL could be indexed, while its historical index report still showed an April robots failure. Those are different observations; a successful live fetch does not erase an old index report.

## Measure the professional record separately

The initial baseline includes 15 fixed search queries on Google and Bing and four fresh prompts each on Google AI Mode, Bing Copilot Search and ChatGPT. It revealed same-name confusion, stale work dates and unsupported education assertions from directory sources. These measurements establish a starting point rather than a before-and-after ranking gain.

The next work is to make useful evidence easier to find on public professional and technical surfaces, then repeat the same queries later. Deployment, crawler access, indexing, factual accuracy and useful visits are tracked separately.

This was personal portfolio maintenance carried out with coding-assistant support. It is not an employer deployment, a customer case study or proof of improved rankings.

[Professional record](../professional/README.md) · [Portfolio](https://robin.ac/) · [Other work accounts](../README.md)
