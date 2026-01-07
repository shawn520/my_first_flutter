import 'package:flutter/material.dart';

/// App localizations base class
abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // App
  String get appName;

  // Welcome screen
  String get welcomeTitle;
  String get welcomeSubtitle;
  String get createNewDatabase;
  String get openExistingDatabase;
  String get masterPassword;
  String get confirmPassword;
  String get create;
  String get unlock;
  String get cancel;
  String get selectSaveLocation;
  String get passwordsDoNotMatch;
  String get passwordTooShort;
  String get pleaseSelectLocation;
  String get pleaseSelectFile;
  String get failedToCreateDatabase;
  String get invalidPasswordOrCorrupted;

  // Unlock screen
  String get databaseLocked;
  String get closeDatabase;
  String get invalidPassword;

  // Home screen
  String get lockDatabase;
  String get exportGroups;
  String get importGroups;
  String get searchEntries;
  String get settings;

  // Groups
  String get groups;
  String get allEntries;
  String get newGroup;
  String get groupName;
  String get renameGroup;
  String get deleteGroup;
  String get deleteGroupConfirm;
  String get noGroupsYet;

  // Entries
  String get entries;
  String get newEntry;
  String get editEntry;
  String get deleteEntry;
  String get deleteEntryConfirm;
  String get noEntriesYet;
  String get addEntry;
  String get title;
  String get username;
  String get password;
  String get url;
  String get notes;
  String get group;
  String get save;
  String get titleRequired;
  String get createdAt;
  String get modifiedAt;
  String get copy;
  String get copied;
  String get copiedClears;

  // Password generator
  String get passwordGenerator;
  String get length;
  String get uppercase;
  String get lowercase;
  String get digits;
  String get symbols;
  String get regenerate;
  String get usePassword;
  String get weak;
  String get fair;
  String get good;
  String get strong;

  // Export
  String get export;
  String get selectGroupsToExport;
  String get selectAll;
  String get expiry;
  String get oneHour;
  String get twentyFourHours;
  String get sevenDays;
  String get thirtyDays;
  String get never;
  String get custom;
  String get exportPassword;
  String get enterOrGeneratePassword;
  String get generate;
  String get passwordRequiredForImport;
  String get selectAtLeastOneGroup;
  String get pleaseEnterPassword;
  String get passwordMinLength;
  String get selectCustomExpiry;
  String get exportSuccessful;
  String get fileSavedTo;
  String get rememberPassword;
  String get ok;

  // Import
  String get import;
  String get selectExportFile;
  String get noFileSelected;
  String get browse;
  String get enterExportPassword;
  String get validateAndPreview;
  String get validating;
  String get fileValidated;
  String get preview;
  String get duplicateGroupsRenamed;
  String get importSuccessful;
  String get importedGroupsAndEntries;
  String get fileNotFound;
  String get invalidFileFormat;
  String get fileExpired;
  String get wrongPassword;
  String get fileCorrupted;
  String get unknownError;

  // Settings
  String get language;
  String get theme;
  String get themeLight;
  String get themeDark;
  String get themeSystem;
  String get chinese;
  String get english;

  // Common
  String get delete;
  String get rename;
  String get error;
  String get success;
  String get warning;
  String items(int count);
  String importedMessage(int groups, int entries);
  String previewCount(int count);
  String get noGroupsAvailable;
  String get databaseNotAvailable;
  String get exportFailed;
  String get importFailed;
  String get validationFailed;
  String get noDataToImport;
  String expiresAt(String date);
  String get passwordCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return AppLocalizationsEn();
      case 'zh':
      default:
        return AppLocalizationsZh();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Chinese translations
class AppLocalizationsZh extends AppLocalizations {
  @override
  String get appName => '密码管理器';

  // Welcome screen
  @override
  String get welcomeTitle => '密码管理器';
  @override
  String get welcomeSubtitle => '本地安全存储您的密码';
  @override
  String get createNewDatabase => '创建新数据库';
  @override
  String get openExistingDatabase => '打开已有数据库';
  @override
  String get masterPassword => '主密码';
  @override
  String get confirmPassword => '确认密码';
  @override
  String get create => '创建';
  @override
  String get unlock => '解锁';
  @override
  String get cancel => '取消';
  @override
  String get selectSaveLocation => '选择保存位置';
  @override
  String get passwordsDoNotMatch => '两次密码不一致';
  @override
  String get passwordTooShort => '密码至少8个字符';
  @override
  String get pleaseSelectLocation => '请选择保存位置';
  @override
  String get pleaseSelectFile => '请选择数据库文件';
  @override
  String get failedToCreateDatabase => '创建数据库失败';
  @override
  String get invalidPasswordOrCorrupted => '密码错误或数据库损坏';

  // Unlock screen
  @override
  String get databaseLocked => '数据库已锁定';
  @override
  String get closeDatabase => '关闭数据库';
  @override
  String get invalidPassword => '密码错误';

  // Home screen
  @override
  String get lockDatabase => '锁定数据库';
  @override
  String get exportGroups => '导出分组';
  @override
  String get importGroups => '导入分组';
  @override
  String get searchEntries => '搜索条目...';
  @override
  String get settings => '设置';

  // Groups
  @override
  String get groups => '分组';
  @override
  String get allEntries => '全部条目';
  @override
  String get newGroup => '新建分组';
  @override
  String get groupName => '分组名称';
  @override
  String get renameGroup => '重命名';
  @override
  String get deleteGroup => '删除分组';
  @override
  String get deleteGroupConfirm => '确定要删除此分组吗？\n\n该分组下的所有条目也将被删除。';
  @override
  String get noGroupsYet => '暂无分组\n点击 + 创建分组';

  // Entries
  @override
  String get entries => '条目';
  @override
  String get newEntry => '新建条目';
  @override
  String get editEntry => '编辑条目';
  @override
  String get deleteEntry => '删除条目';
  @override
  String get deleteEntryConfirm => '确定要删除此条目吗？';
  @override
  String get noEntriesYet => '暂无条目';
  @override
  String get addEntry => '添加条目';
  @override
  String get title => '标题';
  @override
  String get username => '用户名';
  @override
  String get password => '密码';
  @override
  String get url => '网址';
  @override
  String get notes => '备注';
  @override
  String get group => '分组';
  @override
  String get save => '保存';
  @override
  String get titleRequired => '标题不能为空';
  @override
  String get createdAt => '创建时间';
  @override
  String get modifiedAt => '修改时间';
  @override
  String get copy => '复制';
  @override
  String get copied => '已复制';
  @override
  String get copiedClears => '已复制（30秒后清除）';

  // Password generator
  @override
  String get passwordGenerator => '密码生成器';
  @override
  String get length => '长度';
  @override
  String get uppercase => '大写字母';
  @override
  String get lowercase => '小写字母';
  @override
  String get digits => '数字';
  @override
  String get symbols => '符号';
  @override
  String get regenerate => '重新生成';
  @override
  String get usePassword => '使用密码';
  @override
  String get weak => '弱';
  @override
  String get fair => '一般';
  @override
  String get good => '良好';
  @override
  String get strong => '强';

  // Export
  @override
  String get export => '导出';
  @override
  String get selectGroupsToExport => '选择要导出的分组';
  @override
  String get selectAll => '全选';
  @override
  String get expiry => '有效期';
  @override
  String get oneHour => '1小时';
  @override
  String get twentyFourHours => '24小时';
  @override
  String get sevenDays => '7天';
  @override
  String get thirtyDays => '30天';
  @override
  String get never => '永久';
  @override
  String get custom => '自定义';
  @override
  String get exportPassword => '导出密码';
  @override
  String get enterOrGeneratePassword => '输入或生成密码';
  @override
  String get generate => '生成';
  @override
  String get passwordRequiredForImport => '导入文件时需要此密码';
  @override
  String get selectAtLeastOneGroup => '请至少选择一个分组';
  @override
  String get pleaseEnterPassword => '请输入或生成密码';
  @override
  String get passwordMinLength => '密码至少6个字符';
  @override
  String get selectCustomExpiry => '请选择自定义有效期';
  @override
  String get exportSuccessful => '导出成功';
  @override
  String get fileSavedTo => '文件已保存至：';
  @override
  String get rememberPassword => '重要：请记住导出密码！\n导入时需要使用此密码。';
  @override
  String get ok => '确定';

  // Import
  @override
  String get import => '导入';
  @override
  String get selectExportFile => '选择导出文件';
  @override
  String get noFileSelected => '未选择文件';
  @override
  String get browse => '浏览';
  @override
  String get enterExportPassword => '输入导出密码';
  @override
  String get validateAndPreview => '验证并预览';
  @override
  String get validating => '验证中...';
  @override
  String get fileValidated => '文件验证成功';
  @override
  String get preview => '预览';
  @override
  String get duplicateGroupsRenamed => '注意：重名分组将自动重命名';
  @override
  String get importSuccessful => '导入成功';
  @override
  String get importedGroupsAndEntries => '已导入 {0} 个分组，{1} 个条目';
  @override
  String get fileNotFound => '文件不存在';
  @override
  String get invalidFileFormat => '无效的文件格式';
  @override
  String get fileExpired => '文件已过期';
  @override
  String get wrongPassword => '密码错误';
  @override
  String get fileCorrupted => '文件已损坏或被篡改';
  @override
  String get unknownError => '发生未知错误';

  // Settings
  @override
  String get language => '语言';
  @override
  String get theme => '主题';
  @override
  String get themeLight => '浅色';
  @override
  String get themeDark => '深色';
  @override
  String get themeSystem => '跟随系统';
  @override
  String get chinese => '中文';
  @override
  String get english => 'English';

  // Common
  @override
  String get delete => '删除';
  @override
  String get rename => '重命名';
  @override
  String get error => '错误';
  @override
  String get success => '成功';
  @override
  String get warning => '警告';
  @override
  String items(int count) => '$count 项';
  @override
  String importedMessage(int groups, int entries) => '已导入 $groups 个分组，$entries 个条目';
  @override
  String previewCount(int count) => '预览（$count 个分组）';
  @override
  String get noGroupsAvailable => '暂无可用分组';
  @override
  String get databaseNotAvailable => '数据库不可用';
  @override
  String get exportFailed => '导出失败';
  @override
  String get importFailed => '导入失败';
  @override
  String get validationFailed => '验证失败';
  @override
  String get noDataToImport => '无数据可导入';
  @override
  String expiresAt(String date) => '有效期至：$date';
  @override
  String get passwordCopied => '密码已复制';
}

/// English translations
class AppLocalizationsEn extends AppLocalizations {
  @override
  String get appName => 'Password Manager';

  // Welcome screen
  @override
  String get welcomeTitle => 'Password Manager';
  @override
  String get welcomeSubtitle => 'Secure your passwords locally';
  @override
  String get createNewDatabase => 'Create New Database';
  @override
  String get openExistingDatabase => 'Open Existing Database';
  @override
  String get masterPassword => 'Master Password';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get create => 'Create';
  @override
  String get unlock => 'Unlock';
  @override
  String get cancel => 'Cancel';
  @override
  String get selectSaveLocation => 'Select Save Location';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get passwordTooShort => 'Password must be at least 8 characters';
  @override
  String get pleaseSelectLocation => 'Please select a save location';
  @override
  String get pleaseSelectFile => 'Please select a database file';
  @override
  String get failedToCreateDatabase => 'Failed to create database';
  @override
  String get invalidPasswordOrCorrupted => 'Invalid password or corrupted database';

  // Unlock screen
  @override
  String get databaseLocked => 'Database Locked';
  @override
  String get closeDatabase => 'Close Database';
  @override
  String get invalidPassword => 'Invalid password';

  // Home screen
  @override
  String get lockDatabase => 'Lock Database';
  @override
  String get exportGroups => 'Export Groups';
  @override
  String get importGroups => 'Import Groups';
  @override
  String get searchEntries => 'Search entries...';
  @override
  String get settings => 'Settings';

  // Groups
  @override
  String get groups => 'Groups';
  @override
  String get allEntries => 'All Entries';
  @override
  String get newGroup => 'New Group';
  @override
  String get groupName => 'Group Name';
  @override
  String get renameGroup => 'Rename';
  @override
  String get deleteGroup => 'Delete Group';
  @override
  String get deleteGroupConfirm => 'Are you sure you want to delete this group?\n\nAll entries in this group will also be deleted.';
  @override
  String get noGroupsYet => 'No groups yet.\nClick + to create one.';

  // Entries
  @override
  String get entries => 'Entries';
  @override
  String get newEntry => 'New Entry';
  @override
  String get editEntry => 'Edit Entry';
  @override
  String get deleteEntry => 'Delete Entry';
  @override
  String get deleteEntryConfirm => 'Are you sure you want to delete this entry?';
  @override
  String get noEntriesYet => 'No entries yet';
  @override
  String get addEntry => 'Add Entry';
  @override
  String get title => 'Title';
  @override
  String get username => 'Username';
  @override
  String get password => 'Password';
  @override
  String get url => 'URL';
  @override
  String get notes => 'Notes';
  @override
  String get group => 'Group';
  @override
  String get save => 'Save';
  @override
  String get titleRequired => 'Title is required';
  @override
  String get createdAt => 'Created';
  @override
  String get modifiedAt => 'Modified';
  @override
  String get copy => 'Copy';
  @override
  String get copied => 'Copied';
  @override
  String get copiedClears => 'Copied (clears in 30s)';

  // Password generator
  @override
  String get passwordGenerator => 'Password Generator';
  @override
  String get length => 'Length';
  @override
  String get uppercase => 'Uppercase';
  @override
  String get lowercase => 'Lowercase';
  @override
  String get digits => 'Digits';
  @override
  String get symbols => 'Symbols';
  @override
  String get regenerate => 'Regenerate';
  @override
  String get usePassword => 'Use Password';
  @override
  String get weak => 'Weak';
  @override
  String get fair => 'Fair';
  @override
  String get good => 'Good';
  @override
  String get strong => 'Strong';

  // Export
  @override
  String get export => 'Export';
  @override
  String get selectGroupsToExport => 'Select Groups to Export';
  @override
  String get selectAll => 'Select All';
  @override
  String get expiry => 'Expiry';
  @override
  String get oneHour => '1 Hour';
  @override
  String get twentyFourHours => '24 Hours';
  @override
  String get sevenDays => '7 Days';
  @override
  String get thirtyDays => '30 Days';
  @override
  String get never => 'Never';
  @override
  String get custom => 'Custom';
  @override
  String get exportPassword => 'Export Password';
  @override
  String get enterOrGeneratePassword => 'Enter or generate password';
  @override
  String get generate => 'Generate';
  @override
  String get passwordRequiredForImport => 'This password will be required to import the file';
  @override
  String get selectAtLeastOneGroup => 'Please select at least one group';
  @override
  String get pleaseEnterPassword => 'Please enter or generate a password';
  @override
  String get passwordMinLength => 'Password must be at least 6 characters';
  @override
  String get selectCustomExpiry => 'Please select a custom expiry date';
  @override
  String get exportSuccessful => 'Export Successful';
  @override
  String get fileSavedTo => 'File saved to:';
  @override
  String get rememberPassword => 'Important: Remember your export password!\nYou will need it to import this file.';
  @override
  String get ok => 'OK';

  // Import
  @override
  String get import => 'Import';
  @override
  String get selectExportFile => 'Select Export File';
  @override
  String get noFileSelected => 'No file selected';
  @override
  String get browse => 'Browse';
  @override
  String get enterExportPassword => 'Enter the export password';
  @override
  String get validateAndPreview => 'Validate & Preview';
  @override
  String get validating => 'Validating...';
  @override
  String get fileValidated => 'File validated successfully';
  @override
  String get preview => 'Preview';
  @override
  String get duplicateGroupsRenamed => 'Note: Duplicate group names will be automatically renamed.';
  @override
  String get importSuccessful => 'Import Successful';
  @override
  String get importedGroupsAndEntries => 'Imported {0} groups with {1} entries.';
  @override
  String get fileNotFound => 'File not found';
  @override
  String get invalidFileFormat => 'Invalid file format';
  @override
  String get fileExpired => 'Export file has expired';
  @override
  String get wrongPassword => 'Wrong password';
  @override
  String get fileCorrupted => 'File corrupted or tampered';
  @override
  String get unknownError => 'Unknown error occurred';

  // Settings
  @override
  String get language => 'Language';
  @override
  String get theme => 'Theme';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeSystem => 'System';
  @override
  String get chinese => '中文';
  @override
  String get english => 'English';

  // Common
  @override
  String get delete => 'Delete';
  @override
  String get rename => 'Rename';
  @override
  String get error => 'Error';
  @override
  String get success => 'Success';
  @override
  String get warning => 'Warning';
  @override
  String items(int count) => '$count items';
  @override
  String importedMessage(int groups, int entries) => 'Imported $groups groups with $entries entries';
  @override
  String previewCount(int count) => 'Preview ($count groups)';
  @override
  String get noGroupsAvailable => 'No groups available';
  @override
  String get databaseNotAvailable => 'Database not available';
  @override
  String get exportFailed => 'Export failed';
  @override
  String get importFailed => 'Import failed';
  @override
  String get validationFailed => 'Validation failed';
  @override
  String get noDataToImport => 'No data to import';
  @override
  String expiresAt(String date) => 'Expires: $date';
  @override
  String get passwordCopied => 'Password copied';
}
