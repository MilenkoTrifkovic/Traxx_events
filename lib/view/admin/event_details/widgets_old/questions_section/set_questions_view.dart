import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/controller/admin_controllers/set_questions_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/constantsOld.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets_old/questions_section/guest_info_field_widget.dart';
import 'package:traxx_wepapp/widgets/buttons/styled_back_button.dart';

class SetQuestionsView extends StatefulWidget {
  const SetQuestionsView({super.key});

  @override
  State<SetQuestionsView> createState() => _SetQuestionsViewState();
}

class _SetQuestionsViewState extends State<SetQuestionsView> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  final SetQuestionsController setQuestionsController =
      SetQuestionsController();

  @override
  void initState() {
    setQuestionsController.initializeFields();
    super.initState();
  }

  Widget _buildItem(
    EventQuestions item,
    Animation<double> animation,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
          .animate(CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
      )),
      child: GuestInfoFieldWidget(
        key: ValueKey(item.id),
        guestFieldConfig: item,
        guestInfoController: setQuestionsController,
        onDelete: () {
          final int index =
              setQuestionsController.customFieldsList.indexOf(item);
          final removedField =
              setQuestionsController.removeFieldFromList(index);
          _listKey.currentState?.removeItem(
            index,
            (context, animation) => _buildItem(removedField, animation),
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            //waits until animation is done
            setQuestionsController.removeGuestField(item.id!);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: AppPadding.all(context, paddingType: Sizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StyledBackButton(),
                AppText.styledBodySmall(
                    context, 'Every Guest Answers These Questions:',
                    family: ConstantsOld.font2,
                    weight: FontWeight.bold,
                    overflow: TextOverflow.fade),
                AppSpacing.verticalXs(context)
              ],
            ),
            Obx(
              () {
                return setQuestionsController.isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Expanded(
                        child: AnimatedList(
                          padding:
                              AppPadding.bottom(context, paddingType: Sizes.md),
                          controller: _scrollController,
                          shrinkWrap: true,
                          key: _listKey,
                          initialItemCount:
                              setQuestionsController.customFieldsList.length,
                          itemBuilder: (context, index, animation) {
                            return _buildItem(
                                setQuestionsController.customFieldsList[index],
                                animation);
                          },
                        ),
                      );
              },
            ),
            AppSpacing.verticalMd(context),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: AppText.styledBodyMedium(context, 'Create New Field'),
              style: ElevatedButton.styleFrom(
                padding: AppPadding.vertical(context, paddingType: Sizes.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
                ),
              ),
              onPressed: () {
                final index = setQuestionsController.addFieldToList();
                _listKey.currentState?.insertItem(index);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                });
              },
            ),
            AppSpacing.verticalXs(context),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: AppText.styledBodyMedium(context, 'Save'),
              style: ElevatedButton.styleFrom(
                padding: AppPadding.vertical(context, paddingType: Sizes.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
                ),
              ),
              onPressed: () async {
                bool success = await setQuestionsController.saveGuestFields();
                if (success) {
                  popRoute(context);
                } else {
                  SnackBarUtils.showError(context,
                      "Some required fields are missing. Please complete all required fields.");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
