# Fungal Shift Query

This mod displays pending (and/or previous) fungal shifts without invoking
them. Therefore, this mod is compatible with the Fungal Timer mod.

## Prerequisites

This mod depends on the
[https://github.com/dextercd/Noita-Dear-ImGui/releases](Noita-DearImGui) mod.
Note that the Noita-DearImGui mod must appear above Fungal Shift Query in the
mod order.

## Installation

Clone this repository into your Noita mods folder.

## Usage

With the window visible, click `Get Shifts` to list all of the selected shifts. Click `Get Next` to get just the next shift and click `Get Prior` to get just the most recent shift.

If a shift includes `flask or`, then that shift is _guaranteed_ to use a held flask. For example, the text `flask or lava -> water` will convert the material in your held flask to water. If you aren't holding a flask, only then will lava be converted.

If a shift makes no mention of a flask, then a flask will not be used.

Note that the shifts listed are of their original material. Given the following example shifts `Next shift is water -> oil` and `Next+1 shift is water -> steam`, Noita may mention Oil instead of Water for the second shift.

Unless otherwise modded, the game performs a maximum of 20 shifts. Therefore, this mod only predicts up to 20 shifts. Support for additional shifts can be added if desired.

There is no direct support for custom materials.

## Menu

The `Actions` menu contains the following items:

  * `Enable/Disable Debugging` Toggle debugging. This causes the output to include slightly more information.
  * `Clear` Clears the UI text content.
  * `Close` Closes the UI. This just sets the `Enable UI` setting to false.

## Settings

`Previous Count` is the number of past shifts to display. By default, no previous shifts are displayed.

`Next Count` is the number of pending shifts to display. By default, all shifts are displayed.

`Enable UI` controls the UI. If checked, the UI is drawn. If unchecked, the UI is hidden.

## Planned Features

Translation support. Currently the mod displays the material internal name instead of its localized name.

GUI fallback if ImGui is not installed.

