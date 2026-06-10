# 小児体格指数計算アプリ (pediatric_growth)

Androidスマートフォン向け、医療従事者（小児科医）が日常診療で使用することを想定した
小児体格指数の計算・記録・可視化アプリです。Flutter (Dart) 製、完全オフライン動作。

> ⚠️ **医療上の重要な注意**
> 本アプリの計算ロジックは、参照元 Excel
> (`taikakushisu_v3.3`, `taikakubirthlongcross_v1.1`, `plotgrowthchart_v1.21`)
> のセル数式・係数表を解析して**独自に再実装**したものです。
> Excel ファイル自体は再配布禁止のためアプリには含めていません。
> 臨床使用の前に、必ず原典 Excel の出力値と本アプリの出力値を
> 代表的な症例で照合（バリデーション）してください。
> 数値の正確性についていかなる保証もしません。

---

## 機能

### 機能1：在胎期間別出生時体格指数計算（`BirthCalculatorScreen`）
- 在胎週数(22–41)・在胎日数(0–6)、出生体重(g/kg自動換算)、出生身長、出生頭囲、初産/経産
- LMS法による 体重／身長／頭囲 の percentile・SDS
  - 体重：性別×初産経産×在胎週日 別 LMS（新生児基準値）
  - 身長・頭囲：在胎週日 別 LMS（男女共通基準値）
- 検査日入力時、**修正週数**（修正○週○日）での体重・身長・頭囲 percentile・SDS
- 在胎22週未満／42週以上は適用範囲外として「*」表示

### 機能2：体格指数計算（`PatientDetailScreen` の各測定カード）
測定値（身長・体重・IGF-I 任意）から自動計算：
- 年齢（十進・年月）
- 身長SDS（2000年 性別・月齢別 身長基準値）
- 肥満度①（村田式・幼児：1歳以上6歳未満、身長70–120cm）
- 肥満度②（伊藤式・性別年齢別：6歳以上、身長から線形標準体重）
- 肥満度③（伊藤式・性別身長別：6歳以上、身長101–181/174cm、3次式標準体重）
- BMI、BMIパーセンタイル・BMI-SDS（LMS法・18歳未満）
- 体重SDS（Isojima法・月齢別の区分多項式 LMS）
- IGF-Iパーセンタイル・SDS（LMS法・年齢別）

### 機能3：成長曲線描画（`GrowthChartScreen`）
- 身長／体重／BMI のタブ切替
- −2SD・−1SD・中央値・+1SD・+2SD の5本の基準曲線（基準値・LMSから計算生成）
- 患者測定点を時系列でマーカー＋折れ線プロット
- 幼児期(0–6歳)／全体(0–18歳)の表示範囲切替
- ピンチイン・アウトでズーム（`InteractiveViewer`）
- 測定点タップで日付・実測値・SDS をツールチップ表示

### 共通
- 患者データはローカル（Hive）に複数件保存。一覧→選択・編集・削除。
- 患者ごとに複数測定を時系列管理。

---

## 計算ロジックの根拠

| 指標 | 方式 | 実装 |
|------|------|------|
| 身長SDS | 2000年基準 平均±SD | `heightSds` |
| 体重SDS | Isojima et al. 区分多項式 LMS | `weightLms` / `weightSds` |
| BMI-SDS | LMS法（Box-Cox、月齢の3次式 L,M,S） | `bmiLms` |
| 出生時体格 | 在胎週日別 LMS | `birth_calc.dart` |
| 標準体重 | 村田式（幼児）／伊藤式（学童・年齢別/身長別） | `growth_calc.dart` |
| IGF-I | 年齢別 LMS | `igfSds` |
| SDS↔percentile | `SDS=((x/M)^L−1)/(L·S)`, `percentile=Φ(SDS)·100` | `lms.dart`（erf近似） |

数値テーブル（LMS値・多項式係数・基準値）はすべて `lib/data/*.dart` に
`const` として埋め込み済みです（`tools/gen_data.py` で Excel から生成）。

---

## ディレクトリ構成

```
lib/
  main.dart
  calc/
    lms.dart            … LMS式・正規分布(erf)・percentile
    age.dart            … DATEDIF相当の年齢計算
    growth_calc.dart    … 機能2エンジン（身長/体重/BMI/肥満度/IGF）
    birth_calc.dart     … 機能1エンジン（出生時・修正週）
    growth_curves.dart  … 機能3 基準曲線生成
  data/
    height_reference.dart, bmi_lms.dart, weight_sds.dart,
    stdbw.dart, igf_reference.dart, birth_reference.dart  … 係数・基準値
    patient_repository.dart … Hive 永続化
  models/
    patient.dart, measurement.dart
  ui/
    home_screen.dart, patient_edit_screen.dart, patient_detail_screen.dart,
    measurement_edit_screen.dart, birth_calculator_screen.dart,
    growth_chart_screen.dart, format.dart
tools/
  gen_data.py           … Excel→Dartデータ生成スクリプト（参考用）
```

---

## ビルド方法

Flutter SDK (stable, 3.10 以降) が必要です。

```bash
# 1) プラットフォームフォルダを生成（lib/・pubspec.yaml は上書きされません）
flutter create . --platforms=android

# 2) 依存取得
flutter pub get

# 3) 実機/エミュレータで実行
flutter run

# 4) リリースAPK
flutter build apk --release
```

### 最小Android APIレベルについて（重要）

要件は **API 21 (Android 5.0)** でしたが、**現行stable Flutter (3.44) は
API 24 未満を公式サポートしていません**。`FlutterExtension.kt` で
`flutter.minSdkVersion = 24` がハードコードされており、さらにビルド時の
自動マイグレーション（"Upgrading build.gradle.kts"）が
`minSdk = 21` のような明示指定を毎回 `flutter.minSdkVersion` に書き戻します。

そのため**実効 minSdk は 24 (Android 7.0)** になります。21 へ強制上書きすることは
技術的には可能ですが、Flutter エンジン自体が API 21–23 を非サポートのため
古い端末でクラッシュし得るので推奨しません。

- **API 24 で問題ない場合**：そのままビルドできます（検証済み・後述）。
- **API 21 がハード要件の場合**：API 21 をサポートする旧 Flutter
  （例: 3.16 系以前）を使用する必要があります。

### ビルド検証状況（このマシンで実施済み）

| 項目 | 結果 |
|------|------|
| `flutter analyze` | エラー0・警告0（INFO のみ） |
| `flutter test` | 12/12 合格（計算エンジン） |
| `flutter build web` | 成功 |
| `flutter build apk --debug` | 成功（`app-debug.apk`, 約143MB, compileSdk36 / minSdk24 / targetSdk36） |
| 実行（Chrome） | 起動確認（`main()`実行→Hive box オープン→画面描画） |

> ⚠️ **パスに関する注意**：本フォルダはパスに日本語と丸括弧 `(Claude)` を含むため、
> Dart アナライザ（analysis server の LSP）が JSON 解析でクラッシュします。
> 検証は ASCII パス `C:\dev\growth_eval_app` に複製して実施し、そこでは全工程が成功しました。
> **ビルド／解析は ASCII のみのパスにコピーして行うことを強く推奨します。**

> Android のプラットフォームフォルダ（`android/`）は Flutter SDK の
> バージョンに合わせて `flutter create . --platforms=android` で生成するのが
> 最も確実です（`lib/` と `pubspec.yaml` は上書きされません）。

---

## リリース署名（本番ビルド）

リリース用の署名鍵で APK / AAB を生成済みです。

- **keystore**：`C:\dev\keys\growth_eval_app-release.jks`（リポジトリ外。⚠️**要バックアップ**）
- **alias**：`growth_eval_app`
- **認証情報**：`android/key.properties`（gitignore 済み。パスワードはここに格納）
- **証明書フィンガープリント**
  - SHA-1：`DA:67:8D:A8:DD:78:E1:24:1C:86:ED:98:C8:46:C3:3D:07:BE:A4:60`
  - SHA-256：`A7:BB:23:85:50:96:7F:F2:6F:B2:F0:AF:54:74:75:F2:FB:A6:61:A1:53:40:F4:2A:44:5C:8A:CF:CD:00:FF:A3`

> ⚠️ **この keystore を紛失すると、同一アプリの更新版を二度と署名・配信できません**
> （Google Play では特に致命的）。`growth_eval_app-release.jks` と
> `key.properties` のパスワードは安全な場所に必ずバックアップしてください。
> どちらも Git にコミットしないでください（`.gitignore` 済み）。

### 署名付きビルドの作り方

```bash
flutter build apk --release        # build\app\outputs\flutter-apk\app-release.apk
flutter build appbundle --release  # build\app\outputs\bundle\release\app-release.aab
```

成果物は `dist/` にアプリ名＋バージョン＋日付で複製します：
`growth_eval_app_v<version>_<YYYYMMDD>.apk` / `.aab`
（例：`growth_eval_app_v1.0.0+1_20260607.apk`）。バージョンは `pubspec.yaml` の
`version:` を更新してから再ビルドしてください。

署名確認：
```bash
"%ANDROID_HOME%\build-tools\36.0.0\apksigner" verify --print-certs app-release.apk
```

---

## データ再生成（参考）

`tools/gen_data.py` は openpyxl で 3つの Excel を読み、`lib/data/*.dart` を再生成します。
Excel は手元の `~/Downloads` を参照する前提のローカル用スクリプトで、
**Excel 自体はリポジトリに含めません**。

```bash
pip install openpyxl
python tools/gen_data.py
```

