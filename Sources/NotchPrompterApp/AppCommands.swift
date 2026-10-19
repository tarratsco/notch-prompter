import Foundation

final class AppCommands: ObservableObject {
    var openDocument: () -> Void = {}
    var showEditor: () -> Void = {}
    var togglePanelVisibility: () -> Void = {}
    var panelExpansionChanged: () -> Void = {}
    var quit: () -> Void = {}
}
