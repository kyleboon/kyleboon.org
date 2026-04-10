# kyleboon.org

Source for my personal website at [www.kyleboon.org](https://www.kyleboon.org).

Built with Jekyll, zero JavaScript, no CSS framework. Uses the Warm Craft design system (self-hosted Fraunces + Inter fonts, cream/cocoa paper-and-ink palette). See [`docs/style-guide.md`](docs/style-guide.md) for the full design reference.

## Local development

1. Clone the repository
2. Install gems: `bundle install`
3. Run Jekyll: `bundle exec jekyll serve`
4. Open `http://localhost:4000`

## Validation

```bash
bundle exec jekyll build
bundle exec htmlproofer ./_site
```

## License

This project is licensed under the [MIT License](LICENSE).
