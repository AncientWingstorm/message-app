import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/layouts/conversation_list/widgets/header/header_widgets.dart';
import 'package:bluebubbles/app/layouts/conversation_list/pages/search/search_view.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';

class MaterialHeader extends CustomStateful<ConversationListController> {
  const MaterialHeader({Key? key, required super.parentController});

  @override
  State<StatefulWidget> createState() => _MaterialHeaderState();
}

class _MaterialHeaderState extends CustomState<MaterialHeader, void, ConversationListController> {
  bool get showArchived => controller.showArchivedChats;

  bool get showUnknown => controller.showUnknownSenders;
  bool get showDeleted => controller.showDeletedMessages;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() => Container(
              height: controller.selectedChats.isEmpty ? 100 : null,
              width: ns.width(context),
              color: ss.settings.windowEffect.value == WindowEffect.disabled ? context.theme.colorScheme.background : Colors.transparent,
            )),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: controller.selectedChats.isEmpty
              ? SafeArea(
                  child: Obx(() {
                      ns.listener.value;
                      final isMainList = !showArchived && !showUnknown && !showDeleted;
                      // Google Messages style top app bar: title on the left, search + account avatar on the right
                      return Container(
                        height: 64,
                        color: ss.settings.windowEffect.value == WindowEffect.disabled
                            ? context.theme.colorScheme.background
                            : Colors.transparent,
                        padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (ns.isAvatarOnly(context))
                              Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: OverflowMenu(extraItems: true, controller: controller),
                              ),
                            if (!ns.isAvatarOnly(context) && !isMainList)
                              IconButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                },
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: context.theme.colorScheme.onBackground,
                                ),
                              ),
                            if (!ns.isAvatarOnly(context))
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: isMainList ? 16 : 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: HeaderText(controller: controller, fontSize: 22, fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ),
                            if (!ns.isAvatarOnly(context) && isMainList) ...[
                              IconButton(
                                tooltip: "Search",
                                onPressed: () async {
                                  ns.pushLeft(
                                    context,
                                    SearchView(),
                                  );
                                },
                                icon: Icon(
                                  Icons.search,
                                  color: context.theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const OverflowMenu(),
                            ],
                          ],
                        ),
                      );
                    }),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 20.0,
                      left: 20.0,
                      top: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                controller.clearSelectedChats();
                              },
                              icon: Icon(
                                Icons.close,
                                color: context.theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              controller.selectedChats.length.toString(),
                              style: context.theme.textTheme.titleLarge!.copyWith(
                                color: context.theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (([0, controller.selectedChats.length])
                                .contains(controller.selectedChats.where((element) => element.hasUnreadMessage!).length))
                              IconButton(
                                onPressed: () {
                                  for (Chat element in controller.selectedChats) {
                                    element.toggleHasUnread(!element.hasUnreadMessage!);
                                  }
                                  controller.clearSelectedChats();
                                },
                                icon: Icon(
                                  controller.selectedChats[0].hasUnreadMessage! ? Icons.mark_chat_read_outlined : Icons.mark_chat_unread_outlined,
                                  color: context.theme.colorScheme.primary,
                                ),
                              ),
                            if (([0, controller.selectedChats.length])
                                .contains(controller.selectedChats.where((element) => element.muteType == "mute").length))
                              IconButton(
                                onPressed: () {
                                  for (Chat element in controller.selectedChats) {
                                    element.toggleMute(element.muteType != "mute");
                                  }
                                  controller.clearSelectedChats();
                                },
                                icon: Icon(
                                  controller.selectedChats[0].muteType == "mute"
                                      ? Icons.notifications_active_outlined
                                      : Icons.notifications_off_outlined,
                                  color: context.theme.colorScheme.primary,
                                ),
                              ),
                            if (([0, controller.selectedChats.length])
                                .contains(controller.selectedChats.where((element) => element.isPinned!).length))
                              IconButton(
                                onPressed: () {
                                  for (Chat element in controller.selectedChats) {
                                    element.togglePin(!element.isPinned!);
                                  }
                                  controller.clearSelectedChats();
                                },
                                icon: Icon(
                                  controller.selectedChats[0].isPinned! ? Icons.push_pin_outlined : Icons.push_pin,
                                  color: context.theme.colorScheme.primary,
                                ),
                              ),
                            IconButton(
                              onPressed: () {
                                for (Chat element in controller.selectedChats) {
                                  element.toggleArchived(!element.isArchived!);
                                }
                                controller.clearSelectedChats();
                              },
                              icon: Icon(
                                showArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                color: context.theme.colorScheme.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                for (Chat element in controller.selectedChats) {
                                  chats.removeChat(element);
                                  Chat.softDelete(element);
                                }
                                controller.clearSelectedChats();
                              },
                              icon: Icon(
                                Icons.delete_outlined,
                                color: context.theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
