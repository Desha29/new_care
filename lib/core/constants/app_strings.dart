/// النصوص العربية للتطبيق - App Arabic Strings
/// جميع النصوص المعروضة في الواجهة باللغة العربية
class AppStrings {
  AppStrings._();

  // === اسم التطبيق - App Name ===
  static const String appName = 'نيو كير';
  static const String appSubtitle = 'خدمات الرعاية التمريضية';

  // === تسجيل الدخول - Login ===
  static const String login = 'تسجيل الدخول';
  static const String email = 'البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String loginButton = 'دخول';
  static const String loginWelcome = 'مرحباً بك في نيو كير';
  static const String loginSubtitle = 'قم بتسجيل الدخول للمتابعة';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String loginError = 'خطأ في تسجيل الدخول';
  static const String invalidCredentials = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  // === الشريط الجانبي - Sidebar ===
  static const String dashboard = 'لوحة التحكم';
  static const String patients = 'المرضى';
  static const String cases = 'الحالات';
  static const String users = 'المستخدمون';
  static const String inventory = 'المستلزمات الطبية';
  static const String reports = 'التقارير';
  static const String activityLogs = 'سجل الأنشطة';
  static const String settings = 'الإعدادات';
  static const String logout = 'تسجيل الخروج';

  // === لوحة التحكم - Dashboard ===
  static const String todayCases = 'حالات اليوم';
  static const String totalPatients = 'إجمالي المرضى';
  static const String totalRevenue = 'الإيرادات';
  static const String availableNurses = 'الممرضون المتاحون';
  static const String pendingCases = 'حالات معلقة';
  static const String inProgressCases = 'حالات جارية';
  static const String completedCases = 'حالات منتهية';
  static const String recentCases = 'أحدث الحالات';
  static const String revenueOverview = 'نظرة عامة على الإيرادات';
  static const String casesOverview = 'نظرة عامة على الحالات';
  static const String weeklyReport = 'التقرير الأسبوعي';
  static const String monthlyReport = 'التقرير الشهري';
  static const String currency = 'E.P'; // Egyptian Pounds

  // === إدارة المرضى - Patient Management ===
  static const String addPatient = 'إضافة مريض';
  static const String editPatient = 'تعديل بيانات المريض';
  static const String deletePatient = 'حذف المريض';
  static const String patientName = 'اسم المريض';
  static const String patientAge = 'العمر';
  static const String patientPhone = 'رقم الهاتف';
  static const String patientAddress = 'العنوان';
  static const String patientGender = 'الجنس';
  static const String male = 'ذكر';
  static const String female = 'أنثى';
  static const String patientNotes = 'ملاحظات';
  static const String patientHistory = 'التاريخ المرضي';
  static const String patientId = 'رقم المريض';
  static const String searchPatients = 'بحث عن مريض...';
  static const String noPatients = 'لا يوجد مرضى حالياً';

  // === إدارة الحالات - Case Management ===
  static const String addCase = 'إضافة حالة';
  static const String editCase = 'تعديل الحالة';
  static const String deleteCase = 'حذف الحالة';
  static const String caseType = 'نوع الحالة';
  static const String inCenter = 'داخل المركز';
  static const String homeVisit = 'زيارة منزلية';
  static const String assignNurse = 'تعيين ممرض';
  static const String caseStatus = 'حالة الملف';
  static const String pending = 'معلقة';
  static const String inProgress = 'جاري التنفيذ';
  static const String completed = 'منتهية';
  static const String cancelled = 'ملغية';
  static const String services = 'الخدمات';
  static const String supplies = 'المستلزمات المستخدمة';
  static const String totalPrice = 'السعر الإجمالي';
  static const String caseDate = 'تاريخ الحالة';
  static const String caseTime = 'وقت الحالة';
  static const String caseNotes = 'ملاحظات الحالة';
  static const String searchCases = 'بحث عن حالة...';
  static const String noCases = 'لا يوجد حالات حالياً';
  static const String printInvoice = 'طباعة الفاتورة';
  static const String invoicePreview = 'معاينة الفاتورة';

  // === إدارة المستلزمات - Inventory Management ===
  static const String addItem = 'إضافة مستلزم';
  static const String editItem = 'تعديل المستلزم';
  static const String deleteItem = 'حذف المستلزم';
  static const String itemName = 'اسم المستلزم';
  static const String itemQuantity = 'الكمية';
  static const String itemUnit = 'الوحدة';
  static const String itemPrice = 'السعر';
  static const String itemMinStock = 'الحد الأدنى للمخزون';
  static const String lowStock = 'مخزون منخفض';
  static const String outOfStock = 'نفد المخزون';
  static const String inStock = 'متوفر';
  static const String searchInventory = 'بحث عن مستلزم...';
  static const String noInventory = 'لا يوجد مستلزمات حالياً';
  static const String stockAlert = 'تنبيه المخزون';
  static const String stockAlertMessage = 'بعض المستلزمات وصلت للحد الأدنى!';

  // === إدارة المستخدمين - User Management ===
  static const String addUser = 'إضافة مستخدم';
  static const String editUser = 'تعديل المستخدم';
  static const String deleteUser = 'حذف المستخدم';
  static const String userName = 'اسم المستخدم';
  static const String userEmail = 'البريد الإلكتروني';
  static const String userRole = 'الصلاحية';
  static const String superAdmin = 'مدير عام';
  static const String admin = 'مشرف';
  static const String nurse = 'ممرض';
  static const String userPhone = 'رقم الهاتف';
  static const String userActive = 'نشط';
  static const String userInactive = 'غير نشط';
  static const String searchUsers = 'بحث عن مستخدم...';

  // === سجل الأنشطة - Activity Logs ===
  static const String logAction = 'الإجراء';
  static const String logUser = 'المستخدم';
  static const String logDate = 'التاريخ';
  static const String logDetails = 'التفاصيل';
  static const String searchLogs = 'بحث في السجلات...';
  static const String noLogs = 'لا يوجد سجلات حالياً';

  // === الإعدادات - Settings ===
  static const String backup = 'النسخ الاحتياطي';
  static const String backupNow = 'نسخ احتياطي الآن';
  static const String restore = 'استعادة';
  static const String restoreBackup = 'استعادة نسخة احتياطية';
  static const String lastBackup = 'آخر نسخة احتياطية';
  static const String autoBackup = 'نسخ احتياطي تلقائي';
  static const String remoteConfig = 'التحكم عن بُعد';
  static const String featureFlags = 'أعلام الميزات';
  static const String forceUpdate = 'تحديث إجباري';
  static const String killSwitch = 'إيقاف النظام';
  static const String systemStatus = 'حالة النظام';
  static const String appVersion = 'إصدار التطبيق';
  static const String systemActive = 'النظام يعمل';
  static const String systemStopped = 'النظام متوقف';

  // === أزرار عامة - General Buttons ===
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String add = 'إضافة';
  static const String search = 'بحث';
  static const String filter = 'تصفية';
  static const String refresh = 'تحديث';
  static const String print = 'طباعة';
  static const String export = 'تصدير';
  static const String close = 'إغلاق';
  static const String confirm = 'تأكيد';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String ok = 'موافق';
  static const String next = 'التالي';
  static const String previous = 'السابق';
  static const String showAll = 'عرض الكل';

  // === رسائل - Messages ===
  static const String saveSuccess = 'تم الحفظ بنجاح';
  static const String deleteSuccess = 'تم الحذف بنجاح';
  static const String deleteConfirm = 'هل أنت متأكد من الحذف؟';
  static const String deleteConfirmMessage = 'لا يمكن التراجع عن هذا الإجراء';
  static const String errorOccurred = 'حدث خطأ';
  static const String tryAgain = 'حاول مرة أخرى';
  static const String noData = 'لا توجد بيانات';
  static const String loading = 'جاري التحميل...';
  static const String connectionError = 'خطأ في الاتصال';
  static const String offlineMode = 'وضع عدم الاتصال';
  static const String backupSuccess = 'تم النسخ الاحتياطي بنجاح';
  static const String restoreSuccess = 'تمت الاستعادة بنجاح';
  static const String requiredField = 'هذا الحقل مطلوب';
  static const String invalidEmail = 'بريد إلكتروني غير صحيح';
  static const String invalidPhone = 'رقم هاتف غير صحيح';
  static const String noPermission = 'ليس لديك صلاحية لهذا الإجراء';

  // === الطباعة - Printing ===
  static const String invoice = 'فاتورة';
  static const String invoiceNumber = 'رقم الفاتورة';
  static const String invoiceDate = 'تاريخ الفاتورة';
  static const String serviceName = 'اسم الخدمة';
  static const String quantity = 'الكمية';
  static const String unitPrice = 'سعر الوحدة';
  static const String total = 'الإجمالي';
  static const String subtotal = 'المجموع الفرعي';
  static const String discount = 'الخصم';
  static const String grandTotal = 'المجموع الكلي';
  static const String thankYou = 'شكراً لثقتكم في نيو كير';

  // === التقارير - Reports ===
  static const String dailyReport = 'تقرير يومي';
  static const String casesReport = 'تقرير الحالات';
  static const String revenueReport = 'تقرير الإيرادات';
  static const String inventoryReport = 'تقرير المستلزمات';
  static const String nursesReport = 'تقرير الممرضين';
  static const String dateFrom = 'من تاريخ';
  static const String dateTo = 'إلى تاريخ';
  static const String generateReport = 'إنشاء التقرير';
  static const String exportPdf = 'تصدير PDF';
}
