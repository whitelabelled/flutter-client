import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/company_model.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/auth/auth_actions.dart';
import 'package:invoiceninja_flutter/redux/company/company_actions.dart';
import 'package:invoiceninja_flutter/redux/dashboard/dashboard_actions.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/error_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/loading_dialog.dart';
import 'package:invoiceninja_flutter/ui/settings/account_management.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({Key key}) : super(key: key);
  static const String route = '/$kSettings/$kSettingsAccountManagement';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AccountManagementVM>(
      converter: AccountManagementVM.fromStore,
      builder: (context, viewModel) {
        return AccountManagement(
          viewModel: viewModel,
          key: ValueKey(viewModel.state.settingsUIState.updatedAt),
        );
      },
    );
  }
}

class AccountManagementVM {
  AccountManagementVM({
    @required this.state,
    @required this.company,
    @required this.onCompanyChanged,
    @required this.onSavePressed,
    @required this.onCompanyDelete,
    @required this.onPurgeData,
    @required this.onAppliedLicense,
  });

  static AccountManagementVM fromStore(Store<AppState> store) {
    final state = store.state;

    return AccountManagementVM(
        state: state,
        company: state.uiState.settingsUIState.company,
        onCompanyChanged: (company) =>
            store.dispatch(UpdateCompany(company: company)),
        onCompanyDelete: (context, password) {
          showDialog<AlertDialog>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => SimpleDialog(
                    children: <Widget>[LoadingDialog()],
                  ));

          final deleteCompleter = Completer<Null>()
            ..future.then((value) {
              final refreshCompleter = Completer<Null>()
                ..future.then((value) {
                  if (store.state.companies.isNotEmpty) {
                    store.dispatch(SelectCompany(companyIndex: 0));
                    store.dispatch(
                        ViewDashboard(navigator: Navigator.of(context)));

                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    print('## No companies');
                    store.dispatch(UserLogout(context));
                  }
                });
              store.dispatch(
                  RefreshData(clearData: true, completer: refreshCompleter));
            }).catchError((Object error) {
              showDialog<ErrorDialog>(
                  context: context,
                  builder: (BuildContext context) {
                    return ErrorDialog(error);
                  });
            });
          store.dispatch(DeleteCompanyRequest(
              completer: deleteCompleter, password: password));
        },
        onSavePressed: (context) {
          final settingsUIState = state.uiState.settingsUIState;
          final completer = snackBarCompleter<Null>(
              context, AppLocalization.of(context).savedSettings);
          store.dispatch(SaveCompanyRequest(
              completer: completer, company: settingsUIState.company));
        },
        onPurgeData: (context, password) {
          final completer = snackBarCompleter<Null>(
              context, AppLocalization.of(context).purgeSuccessful);
          store.dispatch(
              PurgeDataRequest(completer: completer, password: password));
        },
        onAppliedLicense: () {
          store.dispatch(RefreshData());
        });
  }

  final AppState state;
  final Function(BuildContext) onSavePressed;
  final CompanyEntity company;
  final Function(CompanyEntity) onCompanyChanged;
  final Function(BuildContext, String) onCompanyDelete;
  final Function(BuildContext, String) onPurgeData;
  final Function onAppliedLicense;
}
