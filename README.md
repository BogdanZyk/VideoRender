# VideoRender 🎞️

### Video Processing library. 

The asynchronous video processing library contains many features:

- Merge videos
- Crop size
- Crop time
- Adding text layers
- Adding frame layer
- Mirror video
- Adding audio
- Rotate
- Scale time video
- Change volume video and audio


## 🖥️ Installation

### Requirements
- iOS 16 or macOS 12
- Xcode 14+ and Swift 5.3

### Install
Swift Package Manager (Recommended)
You can install VideoRender into your Xcode project via SPM.
For Xcode 14, navigate to Files → Add Package
Paste the repository URL (https://github.com/BogdanZyk/VideoRender)


# 🛠️ Usage

### Using the renderer for a single input video

```swift
do{

    let render = try await VideoRender(videoURL: videoURL)
    render.addAudio(asset: .init(url: audioUrl), videoLevel: 0.3, musicLevel: 1.0)
    render.crop(cropFrame: .init(x: 100, y: 100, width: 400, height: 400))

    let exporter = try await render.export(exportURL: exportURL, outputFileType: .mp4)

///Finished videoUrl
   print(exporter.outputURL)

}catch{
    print(error.localizedDescription)
}
```


### Using multiple videos to merge

```swift
do{

    let render = try await VideoRender(videoURLs: [videoUrl1, videoUrl2])
    render.scaleTime(timeScale: 0.5)
    let exporter = try await render.export(exportURL: exportURL, outputFileType: .mp4)

///Finished videoUrl
    print(exporter.outputURL)

}catch{
    print(error.localizedDescription)
}
```

# ⤵️ Rendering methods


### 1️⃣ Adds an audio track to a video

startingAt: Track start in seconds or zero, trackDuration: Track duration in seconds or all available video duration, videoLevel/musicLevel - 0...1
```swift
render.addAudio(
    asset: .init(url: audioUrl),
    startingAt: 1, 
    trackDuration: 5, 
    videoLevel: 0.5, 
    musicLevel: 1)
```

### 2️⃣ Adds a frame and text to a video
- videoFrameLayer: Video frame model and size
- textBoxLayers: Text boxes for text layers
- playerFrame: Size of the displayed video area for calculating test box positions

❗️Use only on real device, crash when adding layers on simulator!

```swift 
render.addLayers(
    videoFrameLayer: .init(scaleValue: 0.1, frameColor: .red),
    textBoxLayers: [TextBox(text: "test", offset: .init(width: 100, height: 100),
    timeRange: 0...10)],
    playerFrame: playerFrame
    )
```

### 3️⃣ Crop video time

```swift
render.cropTime(timeRange: .init(start: startTime, end: endTime))
```

### 4️⃣ Crop video size

```swift
render.crop(cropFrame: .init(x: 100, y: 100, width: 400, height: 400))
```

### 5️⃣ Mirror horizontally or vertically

```swift
render.mirror(isHorizontal: true)
render.mirror(isHorizontal: false)
```

### 6️⃣ Rotate video

```swift
render.rotate(rotateDegree: .rotateDegree90)
```

### 7️⃣ Scale video time
TimeScale factor 0.1 - 8.0

```swift
render.scaleTime(timeScale: 0.5)
```

### 8️⃣ Set video volume
volume value 0...1
```swift
render.setVolume(value: 0.3)
```

### Exporter setups

```swift
 let exporter = try await render.export(
    exportURL: exportURL,
    presetName: .exportPreset1280x720,
    optimizeForNetworkUse: false,
    frameRate: .fps60,
    outputFileType: .mp4)
```

### License
VideoRender is created by BogdanZyk and licensed under the [License MIT](https://opensource.org/licenses/MIT)
