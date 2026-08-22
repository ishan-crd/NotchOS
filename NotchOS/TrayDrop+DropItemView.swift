//
//  TrayDrop+DropItemView.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import Foundation
import Pow
import SwiftUI
import UniformTypeIdentifiers

struct DropItemView: View {
    let item: TrayDrop.DropItem
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared

    @State var hover = false

    var body: some View {
        VStack {
            Image(nsImage: item.workspacePreviewImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 64)
            Text(item.fileName)
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .frame(maxWidth: 64)
        }
        .contentShape(Rectangle())
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.5).combined(with: .opacity)
        ))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .scaleEffect(hover ? 1.05 : 1.0)
        .animation(vm.animation, value: hover)
        .onDrag {
            NSItemProvider(object: item.storageURL as NSURL)
        }
        .contextMenu {
            Button {
                QuickLookPreviewer.shared.preview([item.storageURL])
            } label: {
                Label("Quick Look", systemImage: "eye")
            }
            Button {
                NSWorkspace.shared.open(item.storageURL)
            } label: {
                Label("Open", systemImage: "doc")
            }
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.storageURL])
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }
            Divider()
            Button {
                Share(files: [item.storageURL]).begin()
            } label: {
                Label("Share…", systemImage: "square.and.arrow.up")
            }
            Button {
                Share(files: [item.storageURL], serviceName: .sendViaAirDrop).begin()
            } label: {
                Label("AirDrop", systemImage: "airplayaudio")
            }
            Divider()
            Button(role: .destructive) {
                withAnimation(vm.animation) {
                    tvm.delete(item.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onTapGesture {
            guard !vm.optionKeyPressed else { return }
            vm.notchClose()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSWorkspace.shared.open(item.storageURL)
            }
        }
        .overlay {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.red)
                .background(Color.white.clipShape(Circle()).padding(1))
                .frame(width: vm.spacing, height: vm.spacing)
                .opacity(vm.optionKeyPressed ? 1 : 0)
                .scaleEffect(vm.optionKeyPressed ? 1 : 0.5)
                .animation(vm.animation, value: vm.optionKeyPressed)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: vm.spacing / 2, y: -vm.spacing / 2)
                .onTapGesture { tvm.delete(item.id) }
        }
    }
}
