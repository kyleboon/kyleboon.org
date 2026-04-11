---
layout: post
title: Keeping my skills sharp
date: 2025-03-16
description: >-
  How I'm keeping my skills sharp between jobs, comparing Execute Program,
  Boot.dev, Coding Challenges, and codecrafters.io.
---
# Keeping my skills sharp

About a week ago I found out that my job as a Staff Engineer was eliminated as part of restructuring at Wayfair. This was the 5th time something like this had happened during my nearly three years there, so it wasn't a complete shock.

As I dive into the job search, I wanted to find a way to keep my skills sharp. I really don't like "grinding leetcode" as the kids say, for a few reasons. Leetcode skills are not the same as real world skills, and I want to do something that improves my real world programming abilities while also being fun. I'm fairly confident in my abilities to pass a technical interview, so I don't feel the need to spend all my time on that.

## What I actually want to learn

I use databases every day but I've never written a query planner. I've been deploying to Kubernetes for years but couldn't build a container runtime from scratch. I use Redis constantly but I've never implemented the protocol. Though I have a friend who would insist that implementing Redis from scratch is the solution to basically any problem. He's usually right.

I wanted to close gaps like these, not grind algorithm puzzles that I'll forget by next month. I also wanted something structured enough to keep me moving forward on the days when the job search makes it hard to self-motivate. A course, a project, something with stages I can check off.

## What I'm building on the side

I'm also working on two side projects, both chess related because apparently that's where my brain goes when it's unsupervised. The first is a CLI written in Go for analyzing chess games using any UCI chess engine. The second is a web app in TypeScript that I'm not ready to talk about yet.

My real goal with both of these isn't the projects themselves. It's learning to use AI programming tools as something more than a fancy autocomplete. I've been exploring aider, repomix, Claude Code, and Windsurf, trying to figure out where the line is between "the AI wrote this" and "I wrote this with the AI." That line moves every week.

## Options I looked at

I spent some time evaluating structured learning platforms. Here's what I found.

### [Execute Program](https://www.executeprogram.com)

Execute Program is an online learning platform from Gary Bernhardt that uses spaced repetition to help you learn and remember programming concepts. Courses cover Python, JavaScript, TypeScript, SQL, and regular expressions. The lessons are short and you're meant to spend a few minutes a day.

**Pros:**
- Science-backed learning approach with bite-sized lessons
- Built for experienced developers picking up a new language

**Cons:**
- Really designed for learning a new language from scratch, which isn't what I need right now
- Better as a 15-minute morning warm-up than a primary learning tool

**Price:** $39/month or $235/year

### [Boot.dev](https://www.boot.dev)

Boot.dev is a platform aimed at learning backend development through building projects. Courses cover Go, algorithms and data structures, SQL, and more.

**Pros:**
- Project-based approach, focused specifically on backend development

**Cons:**
- Aimed at beginners. I spent an afternoon on it and was speed-running exercises faster than they expected. Their target audience is people learning to code for the first time. I've been doing this since languages I haven't used since high school (in the previous century).

**Price:** $49/month or $348/year

### [Coding Challenges](https://codingchallenges.substack.com)

Coding Challenges is a weekly Substack that posts a new coding challenge every week. The challenges vary quite a bit, from building your own URL shortener to building a chess engine. There's some background and a few steps to get you started, but you're mostly on your own. They also offer bigger courses like Build a Redis Clone, which runs 6 weeks and meets 3 times a week.

**Pros:**
- Wide variety of interesting projects, pick based on what sounds fun
- The Redis clone course would absolutely delight my friend

**Cons:**
- I want something a little more structured. Most of these challenges can't realistically be finished in a week, which would frustrate me. Great source of ideas though.

**Price:** $8/month or $80/year

### [codecrafters.io](https://codecrafters.io)

Codecrafters is a project-based learning platform where every project is in the "Build Your Own X" format. Each one is broken into stages you work through at your own pace, in one of many languages. You push code to their git remote and it runs tests against your current stage.

**Pros:**
- Structured projects that build real-world tools
- Multiple language options per project
- Stage-by-stage progression with automatic test feedback

**Cons:**
- None so far

**Price:** $120/quarter or $360/year

## Why codecrafters won

Codecrafters hooked me because their SQLite project starts at the database file format and works up. The last time I thought about how a database actually stores data was in a college class I barely remember. I'm a few stages in and I can already parse a `.db` file and read the schema, which is more than I could say two weeks ago.

The stage-by-stage approach hits the right balance for me. Each stage gives you enough context and documentation links to get unstuck without telling you exactly what to write. It's guided learning without being prescriptive. And the automatic test runner means I get feedback immediately instead of wondering if my implementation is subtly wrong.

## What's next

I'll write more about the SQLite project once I get past the B-tree implementation, assuming I survive it. I'm also planning to try their Redis and DNS server projects next, since those are tools I use daily without thinking about what's actually happening underneath.

If you're in a similar spot, between jobs and fighting the temptation to just grind LeetCode all day, I'd recommend picking a tool you use every day and trying to build a bad version of it. You'll learn more about the real thing than any interview prep course will teach you.

> **Update (April 2025):** I started as a Principal Software Engineer at RB Global. The job search worked out. The skills sharpening continues.
