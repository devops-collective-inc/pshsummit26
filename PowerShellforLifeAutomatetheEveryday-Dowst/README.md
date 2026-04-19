# PowerShell for Life: Automate the Everyday

**Speaker**: Matthew Dowst

## Overview

PowerShell isn’t just for sysadmins and DevOps pipelines; it’s also a powerful tool for making your everyday life easier, more efficient, and even a little more fun.In this lighthearted but practical session, I’ll share real-world ways I’ve used PowerShell outside the data center and beyond the cloud. From automating the hunt for our dream home, to organizing and deduplicating thousands of old family photos, to sending real-time weather alerts to my kid’s soccer team, and even assigning Secret Santas. PowerShell has been my go-to companion for solving real-life problems with code.We’ll walk through the scripts, logic, and thought processes behind these solutions. You’ll leave with a fresh perspective on what’s possible with PowerShell, along with tips for building your own everyday automations.Whether you’re looking for clever ways to sharpen your skills or just want to see what a little scripting creativity can do, this session will open your eyes to the power of PowerShell in your own life.

---

# Demo Scripts

This folder contains scripts from the "Automate the Everyday" session.

## Script Guide

### Dream Home Automation

- **Find-YourDreamHome.ps1**  
	Loads your existing house-tracking spreadsheet, pulls fresh MLS data, detects listing status changes, adds new listings, then writes a sorted and color-formatted Excel workbook for decision tracking.

- **Get-MLSListing.ps1**  
	Browser-automation helper that opens MLS listing detail pages, scrapes core fields (address, price, beds/baths, status, notes), and returns each listing as a structured PowerShell object.

- **HouseHunt.xlsx**: Example tracking workbook used by the home-search automation.

### Photo Organization And Deduplication

- **Compare-Photos.ps1**  
	Deduplicates large photo sets by first grouping similar file sizes, then sampling image pixels and calculating percentage differences to identify near-identical JPGs.

### Weather Alerts For Team Safety

- **Invoke-WeatherAlert.ps1**  
	Pulls live Wet Bulb Globe Temperature data, classifies heat-risk levels, generates guidance text, and posts alerts to a GroupMe group.

- **Measure-Forecast.ps1**  
	Demonstrates trend forecasting on time-series weather readings using three methods: overall slope, interval-based rates, and linear regression.

### Video Cleanup Automation

- **Trim-VideoByContent.ps1**  
	Uses ffmpeg plus frame-by-frame pixel analysis to remove noisy/duplicate capture windows and trim a video down to the meaningful segment.

### Secret Santa

- **Get-Santa.ps1**  
	Learn how to using back tracing to create a truly customizable and fast secret santa picker. Or really any random picker with custom constraints.