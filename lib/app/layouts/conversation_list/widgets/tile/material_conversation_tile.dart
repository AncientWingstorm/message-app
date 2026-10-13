import 'package:async_task/async_task_extension.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/conversation_list/widgets/tile/conversation_tile.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MaterialConversationTile extends CustomStateful<ConversationTileController> {
  MaterialConversationTile({Key? key, required super.parentController, required this.deletedMode});

  bool deletedMode;

  @override
  State<StatefulWidget> createState() => _MaterialConversationTileState();
}

class _MaterialConversationTileState extends CustomState<MaterialConversationTile, void, ConversationTileController> {
  bool get shouldPartialHighlight => controller.shouldPartialHighlight.value;

  bool get shouldHighlight => controller.shouldHighlight.value;

  bool get hoverHighlight => controller.hoverHighlight.value;

  @override
  void initState() {
    super.initState();
    tag = controller.chat.guid;
    // keep controller in memory since the widget is part of a list
    // (it will be disposed when scrolled out of view)
    forceDelete = false;
  }

  @override
  Widget build(BuildContext context) {
    final leading = ChatLeading(controller: controller);
    final unreadState = GlobalChatService.unreadState(controller.chat.guid);

    final title = Obx(() => ChatTitle(
          parentController: controller,
          style: context.theme.textTheme.bodyLarge!.copyWith(
            color: context.theme.colorScheme.onBackground,
            fontWeight: unreadState.value || controller.shouldHighlight.value ? FontWeight.w700 : FontWeight.w400,
          ),
        ));

    final subtitle = widget.deletedMode
        ? Builder(builder: (context) {
            var count = controller.chat.messages.where((i) => i.dateDeleted != null).length;
            return Text(
              "$count message${count == 1 ? '' : 's'}",
              style: context.theme.textTheme.bodyMedium!.copyWith(color: context.theme.colorScheme.onSurfaceVariant),
            );
          })
        : controller.subtitle ??
            Obx(() {
              final unread = unreadState.value;
              return ChatSubtitle(
                parentController: controller,
                style: context.theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                  color: controller.shouldHighlight.value || unread
                      ? context.theme.colorScheme.onBackground
                      : context.theme.colorScheme.onSurfaceVariant,
                ),
              );
            });

    final trailing = widget.deletedMode
        ? Builder(builder: (context) {
            DateTime oldestDeletion = DateTime.now();
            for (var message in controller.chat.messages) {
              if (message.dateDeleted == null) continue;
              // we are less than the oldest
              if (message.dateDeleted!.compareTo(oldestDeletion) < 0) {
                oldestDeletion = message.dateDeleted!;
              }
            }

            var deleteDate = oldestDeletion.add(const Duration(days: 30));
            var diff = deleteDate.difference(DateTime.now());
            String d;
            if (diff.isNegative) {
              d = "Pending Deletion";
            } else if (diff.inDays != 0) {
              d = "${diff.inDays}d";
            } else if (diff.inHours != 0) {
              d = "${diff.inHours}h";
            } else {
              d = "${diff.inMinutes}m";
            }

            return Text(d, style: context.theme.textTheme.bodySmall!.copyWith(color: context.theme.colorScheme.onSurfaceVariant));
          })
        : MaterialTrailing(parentController: controller);

    // Google Messages style row: avatar, then name + time on the first line and
    // the message snippet (plus pin / mute icons) on the second line
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: MouseCursor.defer,
        onTap: () => controller.onTap(context, widget.deletedMode),
        onSecondaryTapUp: widget.deletedMode ? null : (details) => controller.onSecondaryTap(Get.context!, details),
        onLongPress: widget.deletedMode ? null : controller.onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: ss.settings.denseChatTiles.value ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 8),
                        trailing,
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: subtitle),
                        if (!widget.deletedMode) MaterialTileIcons(parentController: controller),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Obx(() {
      ns.listener.value;
      return AnimatedContainer(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: controller.isSelected
              ? context.theme.colorScheme.secondaryContainer
              : shouldPartialHighlight
                  ? context.theme.colorScheme.gmContainer
                  : shouldHighlight
                      ? context.theme.colorScheme.secondaryContainer
                      : hoverHighlight
                          ? context.theme.colorScheme.gmContainer.withOpacity(0.5)
                          : null,
        ),
        duration: const Duration(milliseconds: 100),
        child: ns.isAvatarOnly(context)
            ? InkWell(
                mouseCursor: MouseCursor.defer,
                onTap: () => controller.onTap(context, widget.deletedMode),
                onSecondaryTapUp: (details) => controller.onSecondaryTap(Get.context!, details),
                onLongPress: controller.onLongPress,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  child: Center(child: leading),
                ),
              )
            : child,
      );
    });
  }
}

/// Pin / mute indicators shown at the end of the snippet line
class MaterialTileIcons extends CustomStateful<ConversationTileController> {
  const MaterialTileIcons({Key? key, required super.parentController});

  @override
  State<StatefulWidget> createState() => _MaterialTileIconsState();
}

class _MaterialTileIconsState extends CustomState<MaterialTileIcons, void, ConversationTileController> {
  @override
  void initState() {
    super.initState();
    tag = controller.chat.guid;
    forceDelete = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final muted = GlobalChatService.muteState(controller.chat.guid).value == "mute";
      final pinned = controller.chat.isPinned ?? false;
      if (!muted && !pinned) return const SizedBox.shrink();
      final color = context.theme.colorScheme.onSurfaceVariant;
      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (muted) Icon(Icons.notifications_off_outlined, size: 16, color: color),
            if (muted && pinned) const SizedBox(width: 4),
            if (pinned) Icon(Icons.push_pin_outlined, size: 16, color: color),
          ],
        ),
      );
    });
  }
}

class MaterialTrailing extends CustomStateful<ConversationTileController> {
  const MaterialTrailing({Key? key, required super.parentController});

  @override
  State<StatefulWidget> createState() => _MaterialTrailingState();
}

class _MaterialTrailingState extends CustomState<MaterialTrailing, void, ConversationTileController> {
  DateTime? dateCreated;
  late final StreamSubscription sub;
  String? cachedLatestMessageGuid = "";
  Message? cachedLatestMessage;

  @override
  void initState() {
    super.initState();
    tag = controller.chat.guid;
    // keep controller in memory since the widget is part of a list
    // (it will be disposed when scrolled out of view)
    forceDelete = false;
    cachedLatestMessage = controller.chat.latestMessage;
    cachedLatestMessageGuid = cachedLatestMessage?.guid;
    dateCreated = cachedLatestMessage?.dateCreated;
    // run query after render has completed
    if (!kIsWeb) {
      updateObx(() {
        final latestMessageQuery = (Database.messages.query(Message_.dateDeleted.isNull())
              ..link(Message_.chat, Chat_.guid.equals(controller.chat.guid))
              ..order(Message_.dateCreated, flags: Order.descending))
            .watch();

        sub = latestMessageQuery.listen((Query<Message> query) async {
          final message = await runAsync(() {
            return query.findFirst();
          });
          if (message != null &&
              ss.settings.statusIndicatorsOnChats.value &&
              (message.dateDelivered != cachedLatestMessage?.dateDelivered || message.dateRead != cachedLatestMessage?.dateRead)) {
            setState(() {});
          }
          cachedLatestMessage = message;
          // check if we really need to update this widget
          if (message != null && message.guid != cachedLatestMessageGuid) {
            if (dateCreated != message.dateCreated) {
              setState(() {
                dateCreated = message.dateCreated;
              });
            }
          }
          cachedLatestMessageGuid = message?.guid;
        });
      });
    } else {
      sub = WebListeners.newMessage.listen((tuple) {
        if (tuple.item2?.guid == controller.chat.guid && (dateCreated == null || tuple.item1.dateCreated!.isAfter(dateCreated!))) {
          cachedLatestMessage = tuple.item1;
          setState(() {
            dateCreated = tuple.item1.dateCreated;
          });
          cachedLatestMessageGuid = tuple.item1.guid;
        }
      });
    }
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unread = GlobalChatService.unreadState(controller.chat.guid).value;

      String indicatorText = "";
      if (ss.settings.statusIndicatorsOnChats.value && (cachedLatestMessage?.isFromMe ?? false) && !controller.chat.isGroup) {
        Indicator show = cachedLatestMessage?.indicatorToShow ?? Indicator.NONE;
        if (show != Indicator.NONE) {
          indicatorText = show.name.toLowerCase().capitalizeFirst!;
        }
      }

      final hasError = (cachedLatestMessage?.error ?? 0) > 0;
      return Text(
        hasError
            ? "Not sent"
            : "${indicatorText.isNotEmpty ? "$indicatorText • " : ""}${buildChatListDateMaterial(cachedLatestMessage?.chatViewDate)}",
        textAlign: TextAlign.right,
        maxLines: 1,
        style: context.theme.textTheme.bodySmall!.copyWith(
          fontSize: 12,
          color: hasError
              ? context.theme.colorScheme.error
              : controller.shouldHighlight.value || unread
                  ? context.theme.colorScheme.onBackground
                  : context.theme.colorScheme.onSurfaceVariant,
          fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
        ),
        overflow: TextOverflow.clip,
      );
    });
  }
}

class UnreadIcon extends CustomStateful<ConversationTileController> {
  const UnreadIcon({Key? key, required super.parentController});

  @override
  State<StatefulWidget> createState() => _UnreadIconState();
}

class _UnreadIconState extends CustomState<UnreadIcon, void, ConversationTileController> {

  @override
  void initState() {
    super.initState();
    tag = controller.chat.guid;
    // keep controller in memory since the widget is part of a list
    // (it will be disposed when scrolled out of view)
    forceDelete = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
      child: (GlobalChatService.unreadState(controller.chat.guid).value)
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                color: context.theme.colorScheme.primary,
              ),
              width: 10,
              height: 10,
            )
          : const SizedBox(width: 10),
    ));
  }
}
