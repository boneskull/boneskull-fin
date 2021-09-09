# Multi-Building Sushi Belts Example

This contains a script which provides various items to three different Curious Builders (100 milestones mod), using a single main belt.  However, this is a general solution for _any_ production building.

## Setup

Each splitter is configured in a manifold like so:

- LEFT output _goes to_ its assigned Curious Builder
- CENTER output _goes to_ the _next splitter in sequence_, or the sink if none remain
- RIGHT output _goes to_ the sink

There's only one Codeable Splitter per building.

Here is a crappy diagram:

```text
              r--------->[Sink]
              |          ^
              |          |
[Machine]<--[Splitter]-->[Sink]
              ^          ^
              |          |
[Machine]<--[Splitter]-->[Sink]
              ^          ^
              |          |
[Machine]<--[Splitter]-->[Sink]
              ^
              |
            [Input]
```

Here's a screenshot, if it works:

![526870_20210909133650_1](https://user-images.githubusercontent.com/924465/132759604-8be41962-3393-4138-a9a8-6a1d232d5ea4.png)


## Behavior

The algorithm, roughly:

- When a codeable splitter receives an `ItemRequest` event _or_ it reaches a 5s timeout, it queries its assigned production building's recipe:
  - IF item **is an ingredient** _and_ **the building's inventory contains less than a full stack** of the item , it sends the item to the **LEFT** output
  - ELSE IF the item **is not an ingredient**, it sends to the **CENTER** output
  - ELSE, it sends to the RIGHT output (sink). This happens in case of overflow as well.

This is important: We count the items which have been sent LEFT by a splitter _but have not yet arrived at the building._  We add this count to the _total_ count of ingredients in the building's inventory.  When an item arrives at the building (a factory connection's `ItemTransfer` event), we decrement the counter.  **If we _did not_ do this, the belt would become backed up and _other_ needed ingredients would never arrive at the building.**

Recipes are cached to avoid needing to check the recipe every time.  If the recipe changes, the computer needs to be rebooted.

If the sink is backed up, we just keep trying to push stuff into it until it works.  This could probably be more elegant.

## Notes

I use a data structure containing multiple pairs of nicknames for my splitters and producers, and reference these directly.  It's likely (maybe?) possible to programmatically determine which splitter "belongs" to which producer, but I haven't tried (yet).

In my case, the final production machine in the line requires output from the two previous machines.  These items rejoin the belt via Mergers just before the final machine.
