# CarPlay Documentation Todo List

This file tracks which CarPlay documentation files have been read and documented in CarPlayNotes.md.

## Guides

### Getting Started

- [x] guides/getting-started/requesting-carplay-entitlements.md
- [x] guides/getting-started/displaying-content-in-carplay.md
- [x] guides/getting-started/using-the-carplay-simulator.md
- [x] guides/getting-started/supporting-previous-versions-of-ios.md

### Integration

- [x] guides/integration/integrating-carplay-with-your-music-app.md
- [ ] ~~guides/integration/integrating-carplay-with-your-navigation-app.md~~ (navigation entitlement only)
- [ ] ~~guides/integration/integrating-carplay-with-your-quick-ordering-app.md~~ (quick-ordering entitlement only)

## API Reference

### Templates

#### Audio

- [x] api-reference/templates/audio/cpnowplayingtemplate.md

#### General

- [x] api-reference/templates/general/cplisttemplate.md
- [x] api-reference/templates/general/cpgridtemplate.md
- [x] api-reference/templates/general/cptabbartemplate.md
- [ ] ~~api-reference/templates/general/cpinformationtemplate.md~~ (not available for audio apps - line 37)
- [ ] ~~api-reference/templates/general/cptextbutton.md~~ (only for CPPointOfInterest and CPInformationTemplate)

#### Alerts

- [x] api-reference/templates/alerts/cpalerttemplate.md
- [x] api-reference/templates/alerts/cpactionsheettemplate.md
- [x] api-reference/templates/alerts/cpalertaction.md

#### Navigation

- [ ] ~~api-reference/templates/navigation/cpmaptemplate.md~~ (navigation entitlement only)
- [ ] ~~api-reference/templates/navigation/cppointofinteresttemplate.md~~ (parking/EV/food entitlement only)
- [ ] ~~api-reference/templates/navigation/cpsearchtemplate.md~~ (navigation entitlement only)

#### Communication

- [ ] ~~api-reference/templates/communication/cpcontacttemplate.md~~ (communication entitlement only)
- [ ] ~~api-reference/templates/communication/cpvoicecontroltemplate.md~~ (navigation entitlement only)

### Types

#### Classes

- [x] api-reference/types/classes/cpbutton.md
- [x] api-reference/types/classes/cpimageset.md
- [ ] ~~api-reference/types/classes/cplane.md~~ (navigation only)
- [ ] ~~api-reference/types/classes/cplaneguidance.md~~ (navigation only)
- [ ] ~~api-reference/types/classes/cpmaneuver.md~~ (navigation only)
- [ ] ~~api-reference/types/classes/cprouteinformation.md~~ (navigation only)

#### Enums

- [ ] ~~api-reference/types/enums/cpjunctiontype.md~~ (navigation only)
- [ ] ~~api-reference/types/enums/cplanestatus.md~~ (navigation only)
- [ ] ~~api-reference/types/enums/cpmaneuverstate.md~~ (navigation only)
- [ ] ~~api-reference/types/enums/cpmaneuvertype.md~~ (navigation only)
- [x] api-reference/types/enums/cpnowplayingmode.md

### Protocols

- [x] api-reference/protocols/cpbarbuttonproviding.md
- [ ] ~~api-reference/protocols/cpinstrumentclustercontrollerdelegate.md~~ (instrument cluster only)
- [x] api-reference/protocols/cptemplate.md

### Scenes

- [x] api-reference/scenes/cptemplateapplicationscene.md
- [ ] ~~api-reference/scenes/cptemplateapplicationdashboardscene.md~~ (navigation only)
- [ ] ~~api-reference/scenes/cptemplateapplicationinstrumentclusterscene.md~~ (instrument cluster only)

### Other

- [x] api-reference/other/overview.md
- [x] api-reference/other/index.md (duplicate of overview.md)
- [x] api-reference/other/topics.md (another duplicate overview)
- [x] api-reference/other/app-main.md (yet another duplicate overview)
- [x] api-reference/other/Reference.md (duplicate overview - same as overview.md)
- [x] api-reference/other/Audio.md (duplicate overview - same as overview.md)
- [x] api-reference/other/Actions-and-Alerts.md (duplicate overview - same as overview.md)
- [x] api-reference/other/CarPlay-Integration.md (duplicate overview - same as overview.md)
- [x] api-reference/other/Classes.md (duplicate overview - same as overview.md)
- [ ] ~~api-reference/other/Communication.md~~ (communication entitlement only)
- [ ] ~~api-reference/other/General-Purpose-Templates.md~~
- [ ] ~~api-reference/other/Instrument-cluster.md~~ (navigation only)
- [ ] ~~api-reference/other/Location-and-Information.md~~ (parking/EV/food only)
- [ ] ~~api-reference/other/Maneuvers.md~~ (navigation only)
- [ ] ~~api-reference/other/Navigation.md~~ (navigation only)
- [ ] ~~api-reference/other/Related-Types.md~~
- [ ] ~~api-reference/other/Routes-lanes-and-junctions.md~~ (navigation only)
- [x] api-reference/other/ac-gn-menustate.md (duplicate overview - same as overview.md)
- [x] api-reference/other/carplay-constants.md
- [x] api-reference/other/carplay-enumerations.md
- [x] api-reference/other/carplayerrordomain.md
- [ ] ~~api-reference/other/cpinstrumentclustercontroller.md~~ (navigation only)
- [ ] ~~api-reference/other/cpnowplayingmodesports.md~~ (sports streaming only)
- [ ] ~~api-reference/other/cpnowplayingsportsclock.md~~ (sports streaming only)
- [ ] ~~api-reference/other/cpnowplayingsportseventstatus.md~~ (sports streaming only)
- [ ] ~~api-reference/other/cpnowplayingsportsteam.md~~ (sports streaming only)
- [ ] ~~api-reference/other/cpnowplayingsportsteamlogo.md~~ (sports streaming only)
- [x] api-reference/other/cpsessionconfiguration.md
- [ ] ~~api-reference/other/cptemplateapplicationdashboardscenedelegate.md~~ (navigation only)
- [ ] ~~api-reference/other/cptemplateapplicationinstrumentclusterscenedelegate.md~~ (navigation only)
- [x] api-reference/other/cptemplateapplicationscenedelegate.md

## Deprecated

- [ ] ~~deprecated/deprecated-symbols.md~~ (not relevant for new implementation)

## Top Level

- [x] carplay/README.md

---

## Notes

- Files marked with ~~strikethrough~~ are not relevant for Blankie (audio app)
- Files marked with [x] have been read and documented
- Files marked with [ ] still need to be reviewed
