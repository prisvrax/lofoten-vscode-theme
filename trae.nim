## ```
## nim r ./trae.nim
## ```
import std/[json, jsonutils, options, os, sequtils, strformat, strutils, syncio, tables, times]

type ExtensionInfo = object
  identifier: tuple[id: string]
  version: string
  location: Table[string, JsonNode]
  relativeLocation: string
  metadata: Option[Table[string, JsonNode]]

const
  editorExtensionPos: string = expandTilde("~/.trae/extensions/")
  editorExtensionFileName: string = "extensions.json"
  lofotenVersion: string = "1.0.0"
  lofotenAuthor: string = "prisvrax"
  lofotenName: string = "lofoten-theme"

let
  extensionName: string = fmt("{lofotenAuthor}.{lofotenName}")
  extensionFolderName: string = fmt("{extensionName}-{lofotenVersion}")
  extensionFolderPath: string = fmt("{editorExtensionPos}{extensionFolderName}")
  extensionLocation: Table[string, JsonNode] = {
    "$mid": newJInt(1),
    "path": newJString(extensionFolderPath),
    "scheme": newJString("file")
  }.toTable()
  extensionMetadata: Table[string, JsonNode] = {
    "installedTimestamp": newJInt(int(getTime().toUnixFloat() * 1000)),
    "pinned": newJBool(true),
    "source": newJString("vsix")
  }.toTable()
  extensionInfo: ExtensionInfo = ExtensionInfo(
    identifier: (id: extensionName),
    version: lofotenVersion,
    location: extensionLocation,
    relativeLocation: extensionFolderName,
    metadata: some(extensionMetadata)
  )

let
  currSrcPath: string = currentSourcePath()
  currSrcDir: string = parentDir(currSrcPath)

var sameExtensionPaths = newSeq[tuple[pcKind: PathComponent, path: string]]()
for extensionItemKind, extensionItemPath in walkDir(editorExtensionPos):
  if lastPathPart(extensionItemPath).startsWith(extensionName):
    sameExtensionPaths.add((pcKind: extensionItemKind, path: extensionItemPath))

var sameExtensionLinks = newSeq[string]()
for (samePcKind, samePath) in sameExtensionPaths:
  case samePcKind:
  of PathComponent.pcDir:
    quit(fmt("{samePath} is an existing folder."))
  of PathComponent.pcFile:
    quit(fmt("{samePath} is an existing file."))
  of PathComponent.pcLinkToFile, PathComponent.pcLinkToDir:
    sameExtensionLinks.add(samePath)

for sameExtensionLink in sameExtensionLinks:
  removeFile(sameExtensionLink)
createSymlink(currSrcDir, extensionFolderPath)

let
  extensionListFile: string = fmt("{editorExtensionPos}{editorExtensionFileName}")
  extensionArrs: seq[ExtensionInfo] = parseFile(extensionListFile).to(seq[ExtensionInfo])
var newExtensionArrs: seq[ExtensionInfo] = extensionArrs.filter do (
  extensionArri: ExtensionInfo) -> bool:
    extensionArri.identifier.id != extensionName
newExtensionArrs.add(extensionInfo)
let newExtensionJson: string = newExtensionArrs.toJson().pretty(2)
writeFile(extensionListFile, newExtensionJson)
