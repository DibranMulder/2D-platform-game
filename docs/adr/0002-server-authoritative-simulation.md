# Make the world simulation server-authoritative

Clients send time-ordered player Intent and servers alone advance movement,
combat, progression, and economy outcomes. This adds latency-compensation work
compared with trusting clients, but reversing an initially client-authoritative
MMO would be both disruptive and insecure; prediction remains a presentation
technique and never transfers authority.

