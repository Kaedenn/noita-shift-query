# Fungal Shift Query

This mod displays pending (and/or previous) fungal shifts without invoking them.

## Prerequisites

This mod depends on the [Noita-DearImGui](https://github.com/dextercd/Noita-Dear-ImGui/releases) mod. Note that this mod must be *below* Noita-DearImGui in the mod order.

## Installation

There are three official methods to install this mod:

1. [Subscribe to this mod via Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3132525756).
2. [Download and extract the zip archive](https://github.com/Kaedenn/noita-shift-query/archive/refs/heads/main.zip) into your mods folder
3. Clone this repository into your mods folder.

## Usage

The main window, when visible, will automatically draw the selected shifts. If for some reason you need to redraw the output, you can click the `Refresh Shifts` button. This will update every time you perform a fungal shift, so the information listed should always be current.

If a shift includes `flask or`, then that shift is _guaranteed_ to use a held flask. For example, the text `flask or lava -> water` will convert the material in your held flask to water. If you aren't holding a flask, only then will lava be converted.

If a shift makes no mention of a flask, then a flask will not be used.

Note that the shifts listed are of their original material. Given the following example shifts `Next shift is water -> oil` and `Next+1 shift is water -> steam`, Noita may mention Oil instead of Water for the second shift.

## Features

  * Accurate flask/pouch indication: if a shift mentions a flask, then a flask or pouch will be used, assuming you're holding one with something in it.
  * Option to display a limited subset of shifts (all, previous, current, next, next two, etc).
  * Option to display greedy shifts (successful greedy shifts are always displayed) (see "Greedy Shifts" below).
  * Option to display either all or the primary shift material for multi-material shifts.
  * Option to enable or disable Alchemic Precursor and Lively Concoction recipes (see "Alchemic Precursor and Lively Concoction" below).
  * Option to show you exactly what materials have been shifted.
  * Option to show a material's internal name, localized name, or both. Note that localized names change with fungal shifts (this is how fungal shifts work) so be careful if you pick that option.
  * Live feedback for shift grace period between consecutive shifts.

### Greedy Shifts

Attempting to shift a material to gold or Holy Grass only has a 0.1% (1/1000) chance of succeeding. Most of the time you'll get one of the "greedy" materials. Successful greedy shifts are always displayed and this shift can be used to obtain large amounts of gold or Holy Grass.

The greedy materials are: brass, silver, toxic sludge, pea soup, flammable gas, poo, mammi, toxic meat, and vomit. Most of the time, attempting to shift a material to gold or Holy Grass will instead shift it to one of these.

### Alchemic Precursor and Lively Concoction

These recipes are randomly generated every seed and take three random materials to generate Alchemic Precursor or Lively Concoction. The behavior is as follows:
`Material_2`, in the presence of `Material_1` and `Material_3`, has a `N` percent chance to become Alchemic Precursor or Lively Concoction. Therefore, you want a large amount of the second material and a small amount of the first and third materials. A higher conversion percentage results in a more efficient conversion.

For example, the Alchemic Precursor recipe of "mud, water, oil" will convert large quantities of water to Alchemic Precursor in the presence of both mud and oil.

## Menu

The `Actions` menu contains the following items:

  * `Refresh` item, which forcibly recalculates everything.
  * Toggle between showing localized material names, internal material names, or both.
  * Option to show either all source materials or just the primary source material, for multi-material shifts.
  * Option to show the shift log, which tells you exactly what was shifted. This works even if a shift used a flask or pouch.
  * Option to toggle displaying Alchemic Precursor and Lively Concoction recipes.
  * Option to show greedy shifts.
  * `Close` item, which just sets the `Enable UI` setting to false.

The `Display` menu contains the following items:

  * `Prior shifts`, allowing you to select between showing one prior shift or all prior shifts.
  * `Next shifts`, allowing you to select between showing just the next shift or showing all pending shifts.
  * `Enable debugging`, which adds a lot of extra diagnostic output.
  * Toggle for displaying colors.
  * Toggle for displaying material icons.

## Settings

  * `Enable UI` - Controls whether or not the UI is visible.
  * `Previous count` - Number of prior shifts to show, between -1 and 20. A value of -1 is interpreted as "show all".
  * `Next count` - Number of pending shifts to show, between -1 and 20. A value of -1 is interpreted as "show all".
  * `Translate?` - Configures how materials are displayed, either using the translated name, internal name, or both.
  * `Expand sources?` - When enabled, all source materials will be displayed. Normally, only the primary material is displayed.
  * `Include AP / LC recipes` - When enabled, the Alchemic Precursor and Lively Concoction recipes will be shown above the shift sequence.
  * `Show Shift Log` - When enabled, a list is shown containing all currently-shifted materials in the order the shifts were made.
  * `Show Greedy Shifts` - When enabled, shifts that use a flask as a destination material will also include what will result when attempting to shift a material to gold.
  * `Color Text` - Controls whether or not text is drawn with colors.
  * `Enable Material Images` - Controls whether or not material images are displayed.

## Planned Features

Add GUI fallback if ImGui is not installed.

Add a window icon.

Add proper internationalization/multi-language support for the static strings.

## See Also

This mod benefits tremendously from GrahamBurger's wonderful [Less Inaccuracies](https://steamcommunity.com/sharedfiles/filedetails/?id=2963870452) mod.

