//
//  SoundSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 5/28/25.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum SoundSheetMode {
  case add
  case edit(CustomSoundData)
}

struct SoundSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let mode: SoundSheetMode

  @State private var soundName: String = ""
  @State private var selectedIcon: String = "waveform.circle"
  @State private var selectedFile: URL?
  @State private var isImporting = false
  @State private var importError: Error?
  @State private var showingError = false
  @State private var isProcessing = false
  @State private var iconSearchText = ""
  @State private var selectedIconCategory = "Popular"

  private var sound: CustomSoundData? {
    switch mode {
    case .add:
      return nil
    case .edit(let sound):
      return sound
    }
  }

  private var title: LocalizedStringKey {
    switch mode {
    case .add:
      return "Import Sound"
    case .edit:
      return "Edit Sound"
    }
  }

  private var buttonTitle: LocalizedStringKey {
    switch mode {
    case .add:
      return "Import Sound"
    case .edit:
      return "Save"
    }
  }

  private var progressMessage: LocalizedStringKey {
    switch mode {
    case .add:
      return "Importing sound..."
    case .edit:
      return "Saving changes..."
    }
  }

  init(mode: SoundSheetMode) {
    self.mode = mode

    switch mode {
    case .add:
      _soundName = State(initialValue: "")
      _selectedIcon = State(initialValue: "waveform.circle")
    case .edit(let sound):
      _soundName = State(initialValue: sound.title)
      _selectedIcon = State(initialValue: sound.systemIconName)
    }
  }

  // Icon categories with curated selections
  private let iconCategories: [String: [String]] = [
    "Popular": [
      "waveform.circle", "speaker.wave.2", "music.note", "waveform",
      "leaf", "drop", "wind", "flame", "bolt", "cloud.rain",
      "cloud.bolt.rain", "beach.umbrella", "tornado", "umbrella",
      "bubbles.and.sparkles", "light.max", "bird", "water.waves",
      "snowflake", "phone.badge.waveform", "text.bubble", "video",
      "fireplace", "train.side.front.car", "airplane", "car", "clock",
      "bed.double", "fan", "bell", "recordingtape",
    ],
    "Nature": [
      // Plants & Basic Elements
      "leaf", "leaf.fill", "tree", "tree.fill", "drop", "drop.fill",
      "flame", "flame.fill", "bolt", "bolt.fill", "rainbow",
      "fossil.shell", "fossil.shell.fill",

      // Sun variations
      "sun.min", "sun.min.fill", "sun.max", "sun.max.fill", "sun.max.circle", "sun.max.circle.fill",
      "sunrise", "sunrise.fill", "sunrise.circle", "sunrise.circle.fill",
      "sunset", "sunset.fill", "sunset.circle", "sunset.circle.fill",
      "sun.horizon", "sun.horizon.fill", "sun.horizon.circle", "sun.horizon.circle.fill",
      "sun.dust", "sun.dust.fill", "sun.dust.circle", "sun.dust.circle.fill",
      "sun.haze", "sun.haze.fill", "sun.haze.circle", "sun.haze.circle.fill",
      "sun.rain", "sun.rain.fill", "sun.rain.circle", "sun.rain.circle.fill",
      "sun.snow", "sun.snow.fill", "sun.snow.circle", "sun.snow.circle.fill",

      // Moon variations
      "moon", "moon.fill", "moon.circle", "moon.circle.fill",
      "moon.dust", "moon.dust.fill", "moon.dust.circle", "moon.dust.circle.fill",
      "moon.haze", "moon.haze.fill", "moon.haze.circle", "moon.haze.circle.fill",
      "moon.stars", "moon.stars.fill", "moon.stars.circle", "moon.stars.circle.fill",
      "star", "star.fill", "sparkles",

      // Cloud variations
      "cloud", "cloud.fill", "cloud.circle", "cloud.circle.fill",
      "cloud.drizzle", "cloud.drizzle.fill", "cloud.drizzle.circle", "cloud.drizzle.circle.fill",
      "cloud.rain", "cloud.rain.fill", "cloud.rain.circle", "cloud.rain.circle.fill",
      "cloud.heavyrain", "cloud.heavyrain.fill", "cloud.heavyrain.circle",
      "cloud.heavyrain.circle.fill",
      "cloud.fog", "cloud.fog.fill", "cloud.fog.circle", "cloud.fog.circle.fill",
      "cloud.hail", "cloud.hail.fill", "cloud.hail.circle", "cloud.hail.circle.fill",
      "cloud.snow", "cloud.snow.fill", "cloud.snow.circle", "cloud.snow.circle.fill",
      "cloud.sleet", "cloud.sleet.fill", "cloud.sleet.circle", "cloud.sleet.circle.fill",
      "cloud.bolt", "cloud.bolt.fill", "cloud.bolt.circle", "cloud.bolt.circle.fill",
      "cloud.bolt.rain", "cloud.bolt.rain.fill", "cloud.bolt.rain.circle",
      "cloud.bolt.rain.circle.fill",
      "cloud.sun", "cloud.sun.fill", "cloud.sun.circle", "cloud.sun.circle.fill",
      "cloud.sun.rain", "cloud.sun.rain.fill", "cloud.sun.rain.circle",
      "cloud.sun.rain.circle.fill",
      "cloud.sun.bolt", "cloud.sun.bolt.fill", "cloud.sun.bolt.circle",
      "cloud.sun.bolt.circle.fill",
      "cloud.moon", "cloud.moon.fill", "cloud.moon.circle", "cloud.moon.circle.fill",
      "cloud.moon.rain", "cloud.moon.rain.fill", "cloud.moon.rain.circle",
      "cloud.moon.rain.circle.fill",
      "cloud.moon.bolt", "cloud.moon.bolt.fill", "cloud.moon.bolt.circle",
      "cloud.moon.bolt.circle.fill",
      "cloud.rainbow.crop", "cloud.rainbow.crop.fill",

      // Wind & Weather phenomena
      "wind", "wind.circle", "wind.circle.fill", "wind.snow", "wind.snow.circle",
      "wind.snow.circle.fill",
      "smoke", "smoke.fill", "smoke.circle", "smoke.circle.fill",
      "snowflake", "snowflake.circle", "snowflake.circle.fill",
      "tornado", "tornado.circle", "tornado.circle.fill",
      "tropicalstorm", "tropicalstorm.circle", "tropicalstorm.circle.fill",
      "hurricane", "hurricane.circle", "hurricane.circle.fill",

      // Temperature & Conditions
      "thermometer.sun", "thermometer.sun.fill", "thermometer.snowflake",
      "thermometer.snowflake.circle", "thermometer.snowflake.circle.fill",
      "thermometer.variable", "thermometer.low", "thermometer.medium", "thermometer.high",
      "aqi.low", "aqi.medium", "aqi.high", "humidity", "humidity.fill",

      // Animals
      "bird", "bird.fill", "fish", "fish.fill", "pawprint", "pawprint.fill",
      "hare", "hare.fill", "tortoise", "tortoise.fill", "teddybear", "teddybear.fill",
    ],
    "Audio": [
      "speaker", "speaker.fill", "speaker.wave.1", "speaker.wave.1.fill", "speaker.wave.2",
      "speaker.wave.2.fill", "speaker.wave.3.fill", "speaker.zzz", "speaker.wave.2.bubble",
      "speaker.wave.2.bubble.fill", "music.note", "music.note.list", "music.mic",
      "music.microphone", "mic", "mic.fill", "waveform", "waveform.circle", "waveform.circle.fill",
      "waveform.badge.exclamationmark", "waveform.badge.magnifyingglass",
      "waveform.and.person.filled",
      "waveform.badge.microphone", "metronome", "metronome.fill", "tuningfork", "headphones",
      "headphones.circle", "headset", "ear", "ear.fill", "recordingtape",
      "recordingtape.circle", "recordingtape.circle.fill", "radio", "radio.fill",
      "antenna.radiowaves.left.and.right.circle", "antenna.radiowaves.left.and.right.circle.fill",
      "hifireceiver", "hifireceiver.fill", "amplifier", "pianokeys", "pianokeys.inverse",
      "guitars", "guitars.fill", "horn", "horn.fill", "horn.blast", "horn.blast.fill",
      "bell", "bell.fill", "bell.badge.waveform", "bell.badge.waveform.fill",
      "bell.and.waves.left.and.right", "bell.and.waves.left.and.right.fill",
    ],
    "Education": [
      "pencil", "pencil.line", "eraser", "eraser.fill", "eraser.line.dashed",
      "eraser.line.dashed.fill", "highlighter", "pencil.and.outline", "pencil.tip",
      "pencil.and.ruler", "book", "book.fill", "books.vertical", "books.vertical.fill",
      "books.vertical.circle", "books.vertical.circle.fill", "magazine", "magazine.fill",
      "newspaper", "newspaper.fill", "newspaper.circle", "newspaper.circle.fill",
      "bookmark", "bookmark.fill", "graduationcap", "graduationcap.fill",
      "graduationcap.circle.fill", "backpack", "backpack.fill", "backpack.circle.fill",
      "studentdesk", "paperclip", "link", "scroll", "scroll.fill", "globe.desk",
      "globe.desk.fill", "compass.drawing",
    ],
    "Sports": [
      "oar.2.crossed", "dumbbell", "dumbbell.fill", "soccerball", "soccerball.inverse",
      "baseball", "baseball.fill", "basketball", "basketball.fill", "american.football",
      "american.football.fill", "american.football.professional",
      "american.football.professional.fill",
      "australian.football", "australian.football.fill", "rugbyball", "rugbyball.fill",
      "tennis.racket", "hockey.puck", "hockey.puck.fill", "cricket.ball", "cricket.ball.fill",
      "tennisball", "tennisball.fill", "volleyball", "volleyball.fill", "skateboard",
      "skateboard.fill", "skis", "skis.fill", "snowboard", "snowboard.fill", "surfboard",
      "surfboard.fill", "duffle.bag", "duffle.bag.fill", "rosette", "trophy", "trophy.fill",
      "medal.star.fill", "flag.fill", "flag.pattern.checkered", "flag.2.crossed",
      "flag.2.crossed.fill", "flag.pattern.checkered.2.crossed", "shield.pattern.checkered",
    ],
    "Tools": [
      "hammer", "hammer.fill", "screwdriver", "screwdriver.fill", "wrench.adjustable",
      "wrench.adjustable.fill", "wrench.and.screwdriver", "wrench.and.screwdriver.fill",
      "paintbrush", "paintbrush.fill", "paintbrush.pointed", "paintbrush.pointed.fill",
      "level", "level.fill", "eyedropper", "eyedropper.halffull", "eyedropper.full",
      "lasso", "lasso.badge.sparkles", "wand.and.rays", "wand.and.sparkles",
      "wand.and.sparkles.inverse", "dial.low", "dial.low.fill", "dial.medium",
      "dial.medium.fill", "dial.high", "dial.high.fill", "gyroscope",
      "gauge.with.dots.needle.bottom.50percent", "gauge.with.dots.needle.100percent",
      "gauge.with.needle", "gauge.with.needle.fill",
    ],
    "Objects": [
      "alarm", "alarm.fill", "clock", "clock.fill", "clock.badge", "clock.badge.fill",
      "deskclock", "deskclock.fill", "alarm.waves.left.and.right",
      "alarm.waves.left.and.right.fill",
      "timer", "timer.circle", "timer.circle.fill", "stopwatch", "stopwatch.fill",
      "hourglass", "hourglass.bottomhalf.filled", "hourglass.tophalf.filled",
      "watch.analog", "fleuron", "fleuron.fill",
      "lightbulb", "lightbulb.fill", "lightbulb.max", "lightbulb.max.fill",
      "lamp.desk", "lamp.desk.fill", "videoprojector", "videoprojector.fill",
      "opticaldisc", "opticaldisc.fill", "lock", "lock.fill", "lock.circle.dotted",
      "lock.square.stack", "lock.open", "lock.open.fill", "key", "key.fill",
      "key.2.on.ring", "key.2.on.ring.fill", "umbrella", "umbrella.fill",
      "beach.umbrella", "beach.umbrella.fill", "megaphone", "megaphone.fill",
      "camera", "camera.fill", "photo.artframe", "film", "film.fill",
      "movieclapper", "movieclapper.fill", "ticket", "ticket.fill",
      "sunglasses", "sunglasses.fill", "crown", "crown.fill", "laser.burst",
      "fireworks", "party.popper", "party.popper.fill", "balloon", "balloon.fill",
      "balloon.2", "balloon.2.fill", "gift", "gift.fill", "birthday.cake",
      "birthday.cake.fill", "theatermasks", "theatermasks.fill",
      "theatermask.and.paintbrush", "theatermask.and.paintbrush.fill",
      "puzzlepiece", "puzzlepiece.fill", "puzzlepiece.extension", "puzzlepiece.extension.fill",
      // Tech/Electronics
      "keyboard", "keyboard.fill", "desktopcomputer", "pc", "flipphone", "candybarphone",
      "computermouse.fill", "hifispeaker", "hifispeaker.fill", "hifispeaker.2",
      "hifispeaker.2.fill", "av.remote", "av.remote.fill", "cable.coaxial",
      "tv", "tv.fill", "tv.inset.filled", "sparkles.tv", "sparkles.tv.fill",
      "gamecontroller.fill",
    ],
    "Home": [
      "house", "house.fill", "house.lodge", "house.lodge.fill", "house.and.flag",
      "house.and.flag.fill",
      "building", "building.fill", "building.2", "building.2.fill",
      "door.left.hand.closed", "door.right.hand.closed", "door.garage.closed",
      "door.french.open", "door.french.closed", "pedestrian.gate.closed", "pedestrian.gate.open",
      "window.vertical.open", "window.vertical.closed", "window.horizontal",
      "window.horizontal.closed",
      "window.ceiling", "window.ceiling.closed", "window.casement", "window.casement.closed",
      "curtains.closed", "sensor", "sensor.fill", "stairs",
      "music.note.house", "music.note.house.fill", "play.house", "play.house.fill",
      "entry.lever.keypad.fill", "bed.double", "bed.double.fill", "sofa", "sofa.fill",
      "chair.lounge", "chair.lounge.fill", "chair", "chair.fill", "fireplace",
      "fireplace.fill", "fan", "fan.fill", "fan.desk", "fan.desk.fill", "fan.floor",
      "fan.floor.fill", "fan.ceiling", "fan.ceiling.fill", "air.conditioner.vertical",
      "air.conditioner.vertical.fill", "air.conditioner.horizontal",
      "air.conditioner.horizontal.fill", "heater.vertical", "heater.vertical.fill",
      "air.purifier", "air.purifier.fill", "dehumidifier", "dehumidifier.fill",
      "humidifier", "humidifier.fill", "washer", "washer.fill", "dryer", "dryer.fill",
      "dishwasher", "dishwasher.fill", "oven", "oven.fill", "stove", "stove.fill",
      "cooktop", "cooktop.fill", "microwave", "microwave.fill", "refrigerator",
      "refrigerator.fill", "sink", "sink.fill", "toilet", "toilet.fill", "bathtub",
      "bathtub.fill", "shower", "shower.fill", "shower.handheld", "shower.handheld.fill",
      "robotic.vacuum", "robotic.vacuum.fill", "sprinkler", "sprinkler.fill",
      "sprinkler.and.droplets", "sprinkler.and.droplets.fill", "spigot", "spigot.fill",
      "wifi.router", "wifi.router.fill", "tent", "tent.fill", "tent.2", "tent.2.fill",
    ],
    "Transport": [
      "car", "car.fill", "car.rear", "car.rear.fill", "car.2", "car.2.fill",
      "bus", "bus.fill", "tram", "tram.fill", "train.side.front.car",
      "airplane", "airplane.departure", "airplane.arrival", "cablecar", "cablecar.fill",
      "lightrail", "lightrail.fill", "ferry", "ferry.fill", "sailboat", "sailboat.fill",
      "bicycle", "stroller", "stroller.fill", "helmet", "helmet.fill",
      "truck.box", "truck.box.fill", "moped", "moped.fill", "motorcycle",
      "motorcycle.fill", "scooter", "gearshift.layout.sixspeed",
    ],
    "Communication": [
      "ellipsis.message.fill", "star.bubble.fill", "text.bubble", "text.bubble.fill",
      "captions.bubble", "captions.bubble.fill", "rectangle.3.group.bubble.fill",
      "bubble.left.and.exclamationmark.bubble.right",
      "bubble.left.and.exclamationmark.bubble.right.fill",
      "phone.bubble.fill", "phone.connection", "phone.badge.waveform", "phone.badge.waveform.fill",
      "phone.arrow.up.right.circle.fill", "phone.down", "phone.down.fill", "phone.down.circle",
      "phone.down.circle.fill", "phone.down.waves.left.and.right", "teletype",
      "video", "video.fill", "video.circle", "video.circle.fill", "video.square",
      "video.square.fill",
      "video.badge.waveform", "video.badge.waveform.fill", "field.of.view.ultrawide",
      "field.of.view.ultrawide.fill", "field.of.view.wide", "field.of.view.wide.fill",
      "printer", "printer.fill", "printer.inverse", "faxmachine", "faxmachine.fill",
      "paperplane", "paperplane.fill", "paperplane.circle",
      "checkmark.seal", "checkmark.seal.fill",
    ],
    "Shopping": [
      "bag", "bag.fill", "cart", "cart.fill", "basket", "basket.fill",
      "wallet.bifold", "wallet.bifold.fill", "handbag", "handbag.fill",
      "briefcase", "briefcase.fill", "case", "case.fill", "suitcase",
      "suitcase.fill", "gearshape", "gearshape.fill", "gearshape.2",
      "gearshape.2.fill", "shippingbox", "shippingbox.fill", "cube", "cube.fill",
    ],
    "Food & Drink": [
      "cup.and.saucer", "cup.and.saucer.fill", "cup.and.heat.waves",
      "cup.and.heat.waves.fill", "mug", "mug.fill", "takeoutbag.and.cup.and.straw",
      "takeoutbag.and.cup.and.straw.fill", "wineglass", "wineglass.fill",
      "waterbottle", "waterbottle.fill", "fork.knife", "frying.pan", "frying.pan.fill",
      "popcorn", "popcorn.fill", "carrot", "carrot.fill", "scalemass", "scalemass.fill",
    ],
    "Entertainment": [
      "arcade.stick.console", "arcade.stick.console.fill", "gamecontroller",
      "gamecontroller.fill", "dice", "dice.fill", "die.face.1.fill", "die.face.2",
      "die.face.2.fill", "die.face.3", "die.face.3.fill", "die.face.4",
      "die.face.4.fill", "die.face.5", "die.face.5.fill", "die.face.6",
      "die.face.6.fill", "paintpalette", "paintpalette.fill", "swatchpalette",
      "swatchpalette.fill",
    ],
    "Medical": [
      "stethoscope", "syringe", "syringe.fill", "pill", "pill.fill", "bandage",
      "bandage.fill", "facemask", "facemask.fill", "flask", "flask.fill",
      "testtube.2", "inhaler", "inhaler.fill", "staroflife.shield.fill",
      "bolt.shield.fill", "bolt.heart", "bolt.heart.fill", "cross.case", "cross.case.fill",
      "medical.thermometer", "medical.thermometer.fill", "waveform.path.ecg",
      "waveform.path.ecg.rectangle", "waveform.path.ecg.rectangle.fill",
    ],
    "People & Activities": [
      // Basic people
      "person", "person.fill", "person.2", "person.2.fill", "person.wave.2", "person.wave.2.fill",
      "person.2.wave.2", "person.2.wave.2.fill", "person.line.dotted.person",
      "person.line.dotted.person.fill",
      "person.3", "person.3.fill", "person.3.sequence", "person.3.sequence.fill",

      // Figure icons
      "figure.stand.dress.line.vertical.figure", "figure.arms.open", "figure.2.arms.open",
      "figure.2.right.holdinghands", "figure.2.left.holdinghands",
      "figure.2.and.child.holdinghands",
      "figure.and.child.holdinghands", "figure", "figure.walk.motion", "figure.wave",
      "figure.fall", "figure.run", "figure.child",

      // Sports activities
      "figure.run.treadmill", "figure.walk.treadmill", "figure.roll", "figure.roll.runningpace",
      "figure.american.football", "figure.archery", "figure.australian.football",
      "figure.badminton",
      "figure.baseball", "figure.basketball", "figure.bowling", "figure.boxing",
      "figure.climbing", "figure.cooldown", "figure.core.training", "figure.cricket",
      "figure.skiing.crosscountry", "figure.cross.training", "figure.curling", "figure.dance",
      "figure.disc.sports", "figure.skiing.downhill", "figure.elliptical",
      "figure.equestrian.sports",
      "figure.fencing", "figure.fishing", "figure.flexibility",
      "figure.strengthtraining.functional",
      "figure.golf", "figure.gymnastics", "figure.hand.cycling", "figure.handball",
      "figure.highintensity.intervaltraining", "figure.hiking", "figure.hockey",
      "figure.field.hockey",
      "figure.ice.hockey", "figure.hunting", "figure.indoor.cycle", "figure.jumprope",
      "figure.kickboxing", "figure.lacrosse", "figure.martial.arts", "figure.mind.and.body",
      "figure.mixed.cardio", "figure.outdoor.cycle", "figure.pickleball", "figure.pilates",
      "figure.play", "figure.pool.swim", "figure.racquetball", "figure.rolling",
      "figure.indoor.rowing", "figure.outdoor.rowing", "figure.rugby", "figure.sailing",
      "figure.skateboarding", "figure.ice.skating", "figure.snowboarding", "figure.indoor.soccer",
      "figure.outdoor.soccer", "figure.socialdance", "figure.softball", "figure.squash",
      "figure.squash.circle.fill", "figure.stair.stepper", "figure.stairs", "figure.step.training",
      "figure.surfing", "figure.table.tennis", "figure.taichi", "figure.tennis",
      "figure.track.and.field", "figure.strengthtraining.traditional", "figure.volleyball",
      "figure.water.fitness", "figure.waterpolo", "figure.wrestling", "figure.yoga",

      // Body parts
      "lungs.fill", "shoeprints.fill", "face.smiling", "face.smiling.inverse",
      "eyes", "eyes.inverse", "nose", "nose.fill", "mustache", "mustache.fill",
      "mouth", "mouth.fill", "brain.head.profile", "brain.head.profile.fill",
      "brain.filled.head.profile", "brain", "brain.fill", "ear", "ear.fill",

      // Hand gestures
      "hand.raised", "hand.raised.fill", "hand.raised.palm.facing", "hand.raised.palm.facing.fill",
      "hand.raised.fingers.spread", "hand.raised.fingers.spread.fill", "hand.thumbsup",
      "hand.thumbsup.fill",
      "hand.thumbsdown", "hand.thumbsdown.fill", "hand.point.up.left", "hand.point.up.left.fill",
      "hand.draw", "hand.draw.fill", "hand.tap", "hand.tap.fill", "hand.rays.fill",
      "hand.point.left", "hand.point.left.fill", "hand.point.right", "hand.point.right.fill",
      "hand.point.up", "hand.point.up.fill", "hand.point.up.braille", "hand.point.up.braille.fill",
      "hand.point.up.braille.badge.ellipsis", "hand.point.down", "hand.point.down.fill",
      "hand.wave", "hand.wave.fill", "hand.palm.facing", "hand.palm.facing.fill",
      "hands.clap", "hands.clap.fill", "hands.and.sparkles", "hands.and.sparkles.fill",
      "hand.pinch", "hand.pinch.fill",

      // Misc
      "person.fill.viewfinder",
    ],
    "Clothing": [
      "hat.widebrim", "hat.widebrim.fill", "hat.cap", "hat.cap.fill",
      "jacket", "jacket.fill", "coat", "coat.fill", "shoe", "shoe.fill",
      "shoe.2", "shoe.2.fill",
    ],
    "Miscellaneous": [
      "trash", "trash.fill", "trash.circle", "trash.circle.fill", "trash.square",
      "signpost.left", "signpost.left.fill", "signpost.right", "signpost.right.fill",
      "signpost.right.and.left", "signpost.right.and.left.fill",
      "signpost.and.arrowtriangle.up", "signpost.and.arrowtriangle.up.fill",
      "globe",
    ],
    "Symbols": [
      "circle", "circle.fill", "square", "square.fill", "rectangle", "rectangle.fill",
      "triangle", "triangle.fill", "triangleshape", "triangleshape.fill",
      "diamond", "diamond.fill", "hexagon", "hexagon.fill", "octagon", "octagon.fill",
      "pentagon", "pentagon.fill", "rhombus", "rhombus.fill",
      "seal", "seal.fill", "shield", "shield.fill",
      "heart", "heart.fill", "star.circle", "star.circle.fill",
      "xmark.triangle.circle.square", "xmark.triangle.circle.square.fill",
    ],
  ]

  private var searchResults: [String] {
    if iconSearchText.isEmpty {
      return iconCategories[selectedIconCategory] ?? []
    }

    // Search across all categories
    let allIcons = iconCategories.values.flatMap { $0 }
    let uniqueIcons = Array(Set(allIcons))

    return uniqueIcons.filter { icon in
      icon.localizedCaseInsensitiveContains(iconSearchText)
    }.sorted()
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header
      VStack(spacing: 8) {
        Text(title)
          .font(.title2.bold())
      }
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      // Content
      VStack(alignment: .leading, spacing: 20) {
        // File selection (only for add mode)
        if case .add = mode {
          fileSelectionSection
        }

        // Name Input
        VStack(alignment: .leading, spacing: 8) {
          Text("Name", comment: "Display name field label")
            .font(.headline)
          TextField(text: $soundName) {
            Text("Enter a name for this sound", comment: "Sound name text field placeholder")
          }
          .textFieldStyle(.roundedBorder)
        }

        // Icon Selection
        iconSelectionSection
      }
      .padding(20)

      Spacer()

      Divider()

      // Footer buttons
      HStack {
        Button("Cancel") {
          dismiss()
        }
        .buttonStyle(.bordered)
        .keyboardShortcut(.escape)

        Spacer()

        Button {
          performAction()
        } label: {
          Text(buttonTitle)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
        .keyboardShortcut(.return)
      }
      .padding()
    }
    .frame(width: 450, height: mode.isAdd ? 580 : 520)
    .fileImporter(
      isPresented: $isImporting,
      allowedContentTypes: [
        UTType.audio,
        UTType.mp3,
        UTType.wav,
        UTType.mpeg4Audio,
      ],
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case .success(let files):
        if let file = files.first {
          selectedFile = file
          // Extract filename (without extension) as default name
          if soundName.isEmpty {
            soundName = file.deletingPathExtension().lastPathComponent
          }
        }
      case .failure(let error):
        importError = error
        showingError = true
      }
    }
    .alert(
      Text("Import Error", comment: "Import error alert title"), isPresented: $showingError,
      presenting: importError
    ) { _ in
      Button("OK", role: .cancel) {}
    } message: { error in
      Text(error.localizedDescription)
    }
    .overlay {
      if isProcessing {
        processingOverlay
      }
    }
  }

  // MARK: - File Selection Section

  private var fileSelectionSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Sound File", comment: "Sound file section header")
        .font(.headline)

      if let selectedFile = selectedFile {
        HStack {
          Image(systemName: "doc.fill")
            .foregroundStyle(.tint)
          VStack(alignment: .leading) {
            Text(selectedFile.lastPathComponent)
              .lineLimit(1)
            Text(formatFileSize(selectedFile))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Button {
            isImporting = true
          } label: {
            Text("Change", comment: "Change file button")
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
        .padding()
        .background(
          Group {
            #if os(macOS)
              Color(NSColor.controlBackgroundColor)
            #else
              Color(UIColor.systemBackground)
            #endif
          }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
      } else {
        Button {
          isImporting = true
        } label: {
          HStack {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
            Text("Select Sound File", comment: "Select sound file button label")
              .font(.headline)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 20)
        }
        .buttonStyle(.bordered)
      }
    }
  }

  // MARK: - Icon Selection Section

  private var iconSelectionSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Icon", comment: "Icon selection label")
          .font(.headline)
        Spacer()
        Text("Selected:", comment: "Selected icon label")
        Image(systemName: selectedIcon)
          .font(.title2)
          .foregroundStyle(.tint)
      }

      // Search and category picker
      HStack(spacing: 8) {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.secondary)
          TextField(text: $iconSearchText) {
            Text("Search icons or enter custom name...", comment: "Icon search field placeholder")
          }
          .textFieldStyle(.plain)
          .onSubmit {
            // If search text is not empty and no results, use it as custom icon
            if !iconSearchText.isEmpty && searchResults.isEmpty {
              selectedIcon = iconSearchText
            }
          }
        }
        .padding(6)
        .background(
          Group {
            #if os(macOS)
              Color(NSColor.controlBackgroundColor)
            #else
              Color(UIColor.systemBackground)
            #endif
          }
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))

        if iconSearchText.isEmpty {
          Picker(
            selection: $selectedIconCategory,
            label: Text("Category", comment: "Icon category picker label")
          ) {
            ForEach(Array(iconCategories.keys).sorted(), id: \.self) { category in
              Text(category).tag(category)
            }
          }
          .pickerStyle(.menu)
          .labelsHidden()
          .frame(width: 120)
        } else if searchResults.isEmpty {
          Button {
            selectedIcon = iconSearchText
          } label: {
            Text("Use Custom", comment: "Use custom icon button")
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
      }

      ScrollView {
        if searchResults.isEmpty && !iconSearchText.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "questionmark.square.dashed")
              .font(.largeTitle)
              .foregroundStyle(.tertiary)
            Text("No matching icons found", comment: "No icon search results message")
              .font(.headline)
            Text(
              "Press Return or click \"Use Custom\" to use \"\(iconSearchText)\" as a custom icon name",
              comment: "Custom icon usage instruction"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 40)
        } else {
          LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(50), spacing: 8), count: 6),
            spacing: 8
          ) {
            ForEach(searchResults, id: \.self) { iconName in
              Button {
                selectedIcon = iconName
              } label: {
                VStack(spacing: 4) {
                  Image(systemName: iconName)
                    .font(.system(size: 24))
                    .frame(height: 30)
                  if !iconSearchText.isEmpty {
                    Text(iconName)
                      .font(.system(size: 8))
                      .lineLimit(1)
                      .truncationMode(.middle)
                  }
                }
                .frame(width: 50, height: iconSearchText.isEmpty ? 50 : 60)
                .background(
                  selectedIcon == iconName
                    ? Color.accentColor.opacity(0.2)
                    : Color.primary.opacity(0.05)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(
                      selectedIcon == iconName ? Color.accentColor : Color.clear,
                      lineWidth: 2
                    )
                )
              }
              .buttonStyle(.plain)
              .help(iconName)
            }
          }
          .padding(4)
        }
      }
      .frame(height: 200)
      .background(
        Group {
          #if os(macOS)
            Color(NSColor.textBackgroundColor)
          #else
            Color(UIColor.systemBackground)
          #endif
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
  }

  // MARK: - Processing Overlay

  private var processingOverlay: some View {
    ZStack {
      Color.black.opacity(0.3)
        .ignoresSafeArea()

      VStack(spacing: 12) {
        ProgressView()
          .scaleEffect(1.5)
        Text(progressMessage)
          .font(.headline)
      }
      .padding(24)
      .background(
        Group {
          #if os(macOS)
            Color(NSColor.windowBackgroundColor)
          #else
            Color(UIColor.systemBackground)
          #endif
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .shadow(radius: 20)
    }
  }

  // MARK: - Helper Methods

  private var isDisabled: Bool {
    let nameTrimmed = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
    switch mode {
    case .add:
      return selectedFile == nil || nameTrimmed.isEmpty || isProcessing
    case .edit:
      return nameTrimmed.isEmpty || isProcessing
    }
  }

  private func performAction() {
    switch mode {
    case .add:
      importSound()
    case .edit(let sound):
      saveChanges(sound)
    }
  }

  private func importSound() {
    guard let selectedFile = selectedFile,
      !soundName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return
    }

    isProcessing = true

    // Capture values before Task to avoid sendability issues
    let file = selectedFile
    let title = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
    let icon = selectedIcon

    Task.detached {
      let result = await CustomSoundManager.shared.importSound(
        from: file,
        title: title,
        iconName: icon
      )

      // Extract sendable values from the result
      let success: Bool
      let errorMessage: String?

      switch result {
      case .success:
        success = true
        errorMessage = nil
      case .failure(let error):
        success = false
        errorMessage = error.localizedDescription
      }

      await MainActor.run {
        isProcessing = false

        if success {
          dismiss()
        } else if let message = errorMessage {
          importError = NSError(
            domain: "ImportError", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
          showingError = true
        }
      }
    }
  }

  private func saveChanges(_ sound: CustomSoundData) {
    guard !soundName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    isProcessing = true

    // Update the sound data
    sound.title = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
    sound.systemIconName = selectedIcon

    do {
      try modelContext.save()

      // Notify that a sound was updated
      NotificationCenter.default.post(name: .customSoundAdded, object: nil)

      // Dismiss the sheet
      dismiss()
    } catch {
      print("❌ SoundSheet: Failed to save changes: \(error)")
      isProcessing = false
    }
  }

  private func formatFileSize(_ url: URL) -> String {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
      let fileSize = attributes[.size] as? Int64
    else {
      return "Unknown size"
    }

    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: fileSize)
  }
}

// MARK: - Mode Extensions

extension SoundSheetMode {
  var isAdd: Bool {
    switch self {
    case .add:
      return true
    case .edit:
      return false
    }
  }
}

// MARK: - Previews

#Preview("Add Mode") {
  SoundSheet(mode: .add)
}

#Preview("Edit Mode") {
  let previewSound = CustomSoundData(
    title: "Sample Sound",
    systemIconName: "waveform",
    fileName: "sample",
    fileExtension: "mp3"
  )

  return SoundSheet(mode: .edit(previewSound))
    .modelContainer(for: CustomSoundData.self, inMemory: true)
}
