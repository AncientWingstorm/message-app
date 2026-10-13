import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ConversationListFAB extends CustomStateful<ConversationListController> {
  const ConversationListFAB({Key? key, required super.parentController});

  @override
  State<StatefulWidget> createState() => _ConversationListFABState();
}

class _ConversationListFABState extends CustomState<ConversationListFAB, void, ConversationListController> {
  void _focusBackToList() {
    if (!FocusScope.of(context).focusInDirection(TraversalDirection.left)) {
      FocusScope.of(context).previousFocus();
    }
  }

  Map<ShortcutActivator, VoidCallback> get _newMessageShortcuts => {
    const SingleActivator(LogicalKeyboardKey.arrowLeft): _focusBackToList,
    const SingleActivator(LogicalKeyboardKey.enter): () => controller.openNewChatCreator(context),
    const SingleActivator(LogicalKeyboardKey.select): () => controller.openNewChatCreator(context),
    const SingleActivator(LogicalKeyboardKey.space): () => controller.openNewChatCreator(context),
  };

  @override
  void initState() {
    super.initState();

    controller.materialScrollController.addListener(() {
      if (!material) return;
      if (controller.materialScrollStartPosition - controller.materialScrollController.offset < -75
          && controller.materialScrollController.position.userScrollDirection == ScrollDirection.reverse
          && controller.showMaterialFABText) {
        setState(() {
          controller.showMaterialFABText = false;
        });
      } else if (controller.materialScrollStartPosition - controller.materialScrollController.offset > 75
          && controller.materialScrollController.position.userScrollDirection == ScrollDirection.forward
          && !controller.showMaterialFABText) {
        setState(() {
          controller.showMaterialFABText = true;
        });
      }
    });
    ns.listener.stream.listen((event) {
      if (!mounted) return;
      if (ns.isAvatarOnly(context) && controller.showMaterialFABText) {
        setState(() {
          controller.showMaterialFABText = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final widget = Obx(() => Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (ss.settings.cameraFAB.value && iOS && !kIsWeb && !kIsDesktop)
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 45,
              maxHeight: 45,
            ),
            child: FloatingActionButton(
              child: Icon(
                iOS ? CupertinoIcons.camera : Icons.photo_camera,
                size: 20,
                color: context.theme.colorScheme.onPrimaryContainer
              ),
              onPressed: () => controller.openCamera(context),
              heroTag: null,
              backgroundColor: context.theme.colorScheme.primaryContainer,
            ),
          ),
        if (ss.settings.cameraFAB.value && iOS && !kIsWeb && !kIsDesktop)
          const SizedBox(
            height: 10,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (chats.chats.isEmpty && chats.loadedChatBatch.value)
            Text("Start a Chat >", style: context.textTheme.labelLarge?.copyWith(color: Colors.white)),
            if (chats.chats.isEmpty)
            const SizedBox(width: 16),
            InkWell(
              onLongPress: iOS || !ss.settings.cameraFAB.value || kIsWeb || kIsDesktop
                ? null : () => controller.openCamera(context),
              child: CallbackShortcuts(
                bindings: _newMessageShortcuts,
                child: FloatingActionButton(
                  focusNode: controller.newMessageFocusNode,
                  backgroundColor: context.theme.colorScheme.primary,
                  child: Icon(
                    iOS ? CupertinoIcons.pencil : Icons.message,
                    color: context.theme.colorScheme.onPrimary,
                    size: 25
                  ),
                  onPressed: () => controller.openNewChatCreator(context)
                ),
              ),
            ),
          ],
        )
      ],
    ));

    return ThemeSwitcher(
      iOSSkin: widget,
      materialSkin: AnimatedCrossFade(
        crossFadeState: controller.selectedChats.isEmpty
            ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 300),
        secondChild: const SizedBox.shrink(),
        // Google Messages style extended "Start chat" FAB that shrinks while scrolling
        firstChild: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onLongPress: ss.settings.cameraFAB.value && !kIsWeb && !kIsDesktop
                ? () => controller.openCamera(context) : null,
            child: CallbackShortcuts(
              bindings: _newMessageShortcuts,
              child: FloatingActionButton.extended(
                heroTag: null,
                focusNode: controller.newMessageFocusNode,
                backgroundColor: context.theme.colorScheme.primaryContainer,
                foregroundColor: context.theme.colorScheme.onPrimaryContainer,
                elevation: 3,
                highlightElevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                isExtended: controller.showMaterialFABText,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
                icon: const Icon(Icons.chat_outlined, size: 24),
                label: Text(
                  "Start chat",
                  style: context.theme.textTheme.labelLarge!.copyWith(
                    color: context.theme.colorScheme.onPrimaryContainer,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => controller.openNewChatCreator(context),
              ),
            ),
          ),
        ),
      ),
      samsungSkin: widget,
    );
  }
}
