import 'dart:io';

/// أداة اختيار الملفات والمجلدات على ويندوز باستخدام PowerShell
/// Windows native file/folder picker using PowerShell dialogs
class WindowsFilePicker {
  WindowsFilePicker._();

  /// اختيار مجلد - Pick a directory
  static Future<String?> pickDirectory() async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      r'''
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = 'اختر مجلد لحفظ النسخة الاحتياطية'
        $dialog.ShowNewFolderButton = $true
        if ($dialog.ShowDialog() -eq 'OK') {
          Write-Output $dialog.SelectedPath
        }
      ''',
    ]);

    final path = result.stdout.toString().trim();
    if (path.isEmpty) return null;
    return path;
  }

  /// اختيار ملف بامتداد محدد - Pick a file with specific extension
  static Future<String?> pickFile({
    String filter = 'Database files (*.db)|*.db',
    String title = 'اختر ملف النسخة الاحتياطية',
  }) async {
    // Escape single quotes in filter and title for PowerShell
    final safeFilter = filter.replaceAll("'", "''");
    final safeTitle = title.replaceAll("'", "''");

    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      '''
        Add-Type -AssemblyName System.Windows.Forms
        \$dialog = New-Object System.Windows.Forms.OpenFileDialog
        \$dialog.Title = '$safeTitle'
        \$dialog.Filter = '$safeFilter'
        \$dialog.FilterIndex = 1
        if (\$dialog.ShowDialog() -eq 'OK') {
          Write-Output \$dialog.FileName
        }
      ''',
    ]);

    final path = result.stdout.toString().trim();
    if (path.isEmpty) return null;
    return path;
  }
}
