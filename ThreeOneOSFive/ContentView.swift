import SwiftUI

struct ContentView: View {
    @State private var isExploiting = false
    @State private var statusMessage = "الجهاز جاهز للبدء"
    @State private var progress: Double = 0.0
    @State private var isSuccess = false
    
    // متغير للتحكم في ظهور أو إخفاء الواجهة
    @State private var isInterfaceHidden = false

    var body: some View {
        ZStack {
            // خلفية الشاشة (تبقى ظاهرة دائماً)
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.0, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            // إذا كانت الواجهة مخفية، يمكنك النقر 3 مرات في أي مكان على الشاشة لإظهارها مجدداً
            .onTapGesture(count: 3) {
                if isInterfaceHidden {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isInterfaceHidden = false
                    }
                }
            }

            // عناصر الواجهة الرئيسية
            if !isInterfaceHidden {
                VStack(spacing: 25) {
                    
                    // المنطقة العلوية (الشعار والعنوان): النقر هنا 3 مرات يؤدي لإخفاء الواجهة
                    VStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.orange)
                            .shadow(color: .orange.opacity(0.8), radius: 10, x: 0, y: 0)
                        
                        Text("VOLCANO")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Tool Kit & Device Management")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle()) // جعل كامل المساحة العلوية قابلة للنقر
                    .onTapGesture(count: 3) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isInterfaceHidden = true
                        }
                    }
                    .padding(.top, 40)

                    Spacer()

                    // بطاقة الحالة والتقدم
                    VStack(spacing: 15) {
                        Text(statusMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if isExploiting {
                            ProgressView(value: progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                .padding(.horizontal, 40)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // زر التنفيذ الرئيسي
                    Button(action: runProcess) {
                        HStack {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "bolt.fill")
                            Text(isExploiting ? "جاري المعالجة..." : (isSuccess ? "تم بنجاح" : "بدء التشغيل"))
                        }
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(
                            isSuccess ? Color.green : (isExploiting ? Color.gray : Color.orange)
                        )
                        .cornerRadius(15)
                        .shadow(color: isSuccess ? .green.opacity(0.4) : .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isExploiting)
                    .padding(.horizontal)

                    Spacer()

                    // معلومات النظام في الأسفل
                    HStack {
                        Label("iOS Supported", systemImage: "cpu")
                        Spacer()
                        Label("v1.0.0", systemImage: "info.circle")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // محاكاة عملية المعالجة والتفعيل
    private func runProcess() {
        isExploiting = true
        isSuccess = false
        progress = 0.0
        statusMessage = "جاري تهيئة النظام..."

        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            DispatchQueue.main.async {
                self.progress += 0.25
                
                switch self.progress {
                case 0.25:
                    self.statusMessage = "جاري قراءة ملفات التكوين..."
                case 0.50:
                    self.statusMessage = "جاري تطبيق الباتشات والموارد..."
                case 0.75:
                    self.statusMessage = "جاري إنهاء العمليات..."
                case 1.0...:
                    timer.invalidate()
                    self.isExploiting = false
                    self.isSuccess = true
                    self.statusMessage = "تمت العملية بنجاح!"
                default:
                    break
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
