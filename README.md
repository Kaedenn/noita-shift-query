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

The main window, when visible, will automatically draw the selected shifts. If for some reason you need to redraw the output, you can click the `Refresh Shifts` button. This will update every time you perform a fungal shift, so the information listed should always be current.

If a shift includes `flask or`, then that shift is _guaranteed_ to use a held flask. For example, the text `flask or lava -> water` will convert the material in your held flask to water. If you aren't holding a flask, only then will lava be converted.

If a shift makes no mention of a flask, then a flask will not be used.

Note that the shifts listed are of their original material. Given the following example shifts `Next shift is water -> oil` and `Next+1 shift is water -> steam`, Noita may mention Oil instead of Water for the second shift.

Unless otherwise modded, the game performs a maximum of 20 shifts. Therefore, this mod only predicts up to 20 shifts. Support for additional shifts can be added if desired.

There is no direct support for custom materials.

## Menu

The `Actions` menu contains the following items:

  * `Enable/Disable Translations` Toggle localization support. This causes the output to use translated material names instead of their internal names.
  * `Enable/Disable Debugging` Toggle debugging. This causes the output to include slightly more information.
  * `Clear` Clears the UI text content.
  * `Close` Closes the UI. This just sets the `Enable UI` setting to false.
  * `Do Custom Shift` (TODO: WIP) Force a custom shift, outside of the game's normal shift routine. This allows you to shift any two arbitrary materials, even those not normally shiftable.

## Settings

`Previous Count` is the number of past shifts to display. By default, no previous shifts are displayed.

`Next Count` is the number of pending shifts to display. By default, all shifts are displayed.

`Translate` toggles between displaying internal names (`magic_liquid_berserk`) and localized names (`Berserkium`)

`Enable UI` controls the UI. If checked, the UI is drawn. If unchecked, the UI is hidden.

## Planned Features

Add GUI fallback if ImGui is not installed.

Add a window icon.

Add proper internationalization/multi-language support for the static strings.

