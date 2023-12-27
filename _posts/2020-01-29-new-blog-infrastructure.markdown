---
layout: post
title: Leaving Octopress
date: 2020-01-29 13:57
---

After 6 years using octopress, I've finally admitted it is dead. I decided to switch to plain jekyll which I should have done a long time ago. My only requirement was to change the URL format on the off chance anyone has ever linked to my blog. I also wanted an extremely simple theme that didn't have tons of css I didn't understand or need.  I picked one called `Beautiful Jekyll`

> **Beautiful Jekyll** is a ready-to-use template to help you create an awesome website quickly. Perfect for personal sites, blogs, or simple project websites.  [Check out a demo](https://deanattali.com/beautiful-jekyll) of what you'll get after just two minutes.  You can also look at [his personal website](https://deanattali.com) to see it in use.

The process was very simple.

* Fork and clone `Beautiful Jekyll`
* Delete everything in `_posts`
* Delete everything except the `_posts` and the images from my old octopress site. Commit that to git.
* Copy the `Beautiful Jekyll` site over to mine, ignoring all the git related stuff. Commit that to git.
* Update `_config.yml` with the values for my blog
    * The most important change was to `permalink` to keep the octopress url format. It should be set to `/blog/:year/:month/:day/:title/`
* I installed `html-proofer` to look for broken external links and images.
    * `gem 'html-proofer'` in your Gemfile. Then `bundle install` and generate the site `bundle exec jekyll build` and run `bundle exec htmlproofer ./_site`. It found a lot of broken links some html issues as well.  
* `bundle exec jekyll serve` and make sure it looks reasonable

To deploy I decided to set up Amazon Amplify which was also super easy. I pointed it to my public github repo and it recognized it as a jekyll site and configured Amplify to generate and deploy after every commit. Then I had Amplify take over the domain name from the s3 bucket that was configured before and everything was done. 