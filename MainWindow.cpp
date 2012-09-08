#include "MainWindow.h"
#include "ui_MainWindow.h"
#include <QStandardItemModel>
#include <QItemDelegate>
#include <QComboBox>
#include <QSpinBox>
#include <QDoubleSpinBox>
#include <QTextStream>
#include <QTextDocument>
#include <QFile>
#include <QFileDialog>
#include <QMessageBox>
#include <map>

//
// ComboBoxDelegate
//

ComboBoxDelegate::ComboBoxDelegate(QObject *parent) : QItemDelegate(parent) {}
QWidget *ComboBoxDelegate::createEditor(QWidget *parent,const QStyleOptionViewItem &, const QModelIndex &) const
{
    QComboBox* comboBox = new QComboBox(parent);
    comboBox->addItems(itemList);
    return comboBox;
}
void ComboBoxDelegate::setEditorData(QWidget *editor, const QModelIndex &index) const
{
   QString value = index.model()->data(index, Qt::EditRole).toString();
   QComboBox *cBox = static_cast<QComboBox*>(editor);
   cBox->setCurrentIndex(cBox->findText(value));
}
void ComboBoxDelegate::setModelData(QWidget *editor, QAbstractItemModel *model, const QModelIndex &index) const
{
   QComboBox *cBox = static_cast<QComboBox*>(editor);
   QString value = cBox->currentText();
   model->setData(index, value, Qt::EditRole);
}
void ComboBoxDelegate::updateEditorGeometry(QWidget *editor, const QStyleOptionViewItem &option, const QModelIndex &) const { editor->setGeometry(option.rect); }

//-----------------------------------------------------------------------------------

//
// SpinBoxDelegate
//

SpinBoxDelegate::SpinBoxDelegate(QObject *parent) : QItemDelegate(parent) {}
QWidget *SpinBoxDelegate::createEditor(QWidget *parent,const QStyleOptionViewItem &, const QModelIndex &) const
{
    QSpinBox *editor = new QSpinBox(parent);
    editor->setMinimum(Min);
    editor->setMaximum(Max);
    return editor;
}
void SpinBoxDelegate::setEditorData(QWidget *editor, const QModelIndex &index) const
{
    int value = index.model()->data(index, Qt::EditRole).toInt();
    QSpinBox *spinBox = static_cast<QSpinBox*>(editor);
    spinBox->setValue(value);
}
void SpinBoxDelegate::setModelData(QWidget *editor, QAbstractItemModel *model, const QModelIndex &index) const
{
    QSpinBox *spinBox = static_cast<QSpinBox*>(editor);
    spinBox->interpretText();
    int value = spinBox->value();
    model->setData(index, value, Qt::EditRole);
}
void SpinBoxDelegate::updateEditorGeometry(QWidget *editor, const QStyleOptionViewItem &option, const QModelIndex &) const { editor->setGeometry(option.rect); }

//----------------------------------------------------------------------

//
// DoubleSpinBoxDelegate
//

DoubleSpinBoxDelegate::DoubleSpinBoxDelegate(QObject *parent) : QItemDelegate(parent) {}
QWidget *DoubleSpinBoxDelegate::createEditor(QWidget *parent,const QStyleOptionViewItem &, const QModelIndex &) const
{
    QDoubleSpinBox *editor = new QDoubleSpinBox(parent);
    editor->setMinimum(Min);
    editor->setMaximum(Max);
    return editor;
}
void DoubleSpinBoxDelegate::setEditorData(QWidget *editor, const QModelIndex &index) const
{
    double value = index.model()->data(index, Qt::EditRole).toDouble();
    QDoubleSpinBox *spinBox = static_cast<QDoubleSpinBox*>(editor);
    spinBox->setValue(value);
}
void DoubleSpinBoxDelegate::setModelData(QWidget *editor, QAbstractItemModel *model, const QModelIndex &index) const
{
    QDoubleSpinBox *spinBox = static_cast<QDoubleSpinBox*>(editor);
    spinBox->interpretText();
    int value = spinBox->value();
    model->setData(index, value, Qt::EditRole);
}
void DoubleSpinBoxDelegate::updateEditorGeometry(QWidget *editor, const QStyleOptionViewItem &option, const QModelIndex &) const { editor->setGeometry(option.rect); }

//----------------------------------------------------------------------

//
// MainWindow
//

void MainWindow::UpdateRegisters()
{
    QString ireg_pre = "$" + generalModel->item(IREG_PREFIX)->text();
    QString freg_pre = "$" + generalModel->item(FREG_PREFIX)->text();
    QString tmp;
    int ireg_num = generalModel->item(IREG_NUM)->text().toInt();
    int freg_num = generalModel->item(FREG_NUM)->text().toInt();
    iregs.clear();
    fregs.clear();
    for (int i = 0; i < ireg_num; i++)
    {
        iregs << (ireg_pre + tmp.number(i));
    }
    for (int i = 0; i < freg_num; i++)
    {
        fregs << (freg_pre + tmp.number(i));
    }
}

void MainWindow::InitGeneralTV()
{
    generalOptions
        << "アーキテクチャ名"
        << "バイナリファイルのエンディアン"
        << "ROM（命令メモリを格納する領域）サイズ"
        << "ROMアドレッシング"
        << "RAM（プログラム実行時の作業用領域）サイズ"
        << "RAMアドレッシング"
        << "コメントアウト記号"
        << "整数レジスタ接頭辞"
        << "浮動小数レジスタ接頭辞"
        << "整数レジスタ数"
        << "浮動小数レジスタ数"
        << "キャッシュに使う浮動小数レジスタ数"
        << "ゼロレジスタ"
        << "フレームレジスタ"
        << "ヒープレジスタ"
        << "リンクレジスタ"
        << "1固定レジスタ"
        << "-1固定レジスタ";

    QStandardItemModel* model = new QStandardItemModel();
    generalModel = model;
    int row = 0;
    model->setItem(row++, 0, new QStandardItem("myArchitecture"));

    ComboBoxDelegate *cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << "リトルエンディアン" << "ビッグエンディアン";
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(cdel->itemList[0]));
    //
    // ROM
    //
    QStandardItem* item = new QStandardItem("64KB(固定)"); item->setEditable(false);
    model->setItem(row++, 0, item);
    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << "ワードアドレッシング" << "バイトアドレッシング";
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(cdel->itemList[0]));
    //
    // RAM
    //
    DoubleSpinBoxDelegate *ddel = new DoubleSpinBoxDelegate(ui->GeneralTV);
    ddel->Max = 99; ddel->Min = 0;
    ui->GeneralTV->setItemDelegateForRow(row, ddel);//デリゲートセット
    model->setItem(row++, 0, new QStandardItem("8.00"));
    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << "ワードアドレッシング" << "バイトアドレッシング";
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(cdel->itemList[0]));
    //
    // コメントアウト
    //
    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << "#" << "!" << "//" << "--";
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(cdel->itemList[0]));
    //
    // レジスタ接頭辞
    //
    model->setItem(row++, 0, new QStandardItem("r"));
    model->setItem(row++, 0, new QStandardItem("f"));
    //
    // レジスタ数
    //
    SpinBoxDelegate *sdel = new SpinBoxDelegate(ui->GeneralTV);
    sdel->Max = 32; sdel->Min = 1;
    ui->GeneralTV->setItemDelegateForRow(row, sdel);
    model->setItem(row++, 0, new QStandardItem("32"));
    sdel = new SpinBoxDelegate(ui->GeneralTV);
    sdel->Max = 32; sdel->Min = 1;
    ui->GeneralTV->setItemDelegateForRow(row, sdel);
    model->setItem(row++, 0, new QStandardItem("32"));
    sdel = new SpinBoxDelegate(ui->GeneralTV);
    sdel->Max = 16; sdel->Min = 0;
    ui->GeneralTV->setItemDelegateForRow(row, sdel);
    model->setItem(row++, 0, new QStandardItem("16"));
    //
    // 特殊レジスタ
    //
    UpdateRegisters();

    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << iregs;
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(iregs[0]));

    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << iregs;
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(iregs[1]));

    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << iregs;
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(iregs[2]));

    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << "専用レジスタを使用" << iregs;
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(cdel->itemList[0]));

    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << iregs;
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(iregs[iregs.length() - 2]));

    cdel = new ComboBoxDelegate(ui->GeneralTV);
    cdel->itemList << iregs;
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    model->setItem(row++, 0, new QStandardItem(iregs[iregs.length() - 1]));

    model->setVerticalHeaderLabels(generalOptions);
    ui->GeneralTV->setModel(model);
    ui->GeneralTV->resizeColumnsToContents();
    ui->GeneralTV->resizeRowsToContents();
}

void MainWindow::AddRow(
        QStandardItemModel* model,
        int row,
        QString instName,
        bool useCheckBox,
        QString args,
        QString opcode,
        QString funct,
        QString code,
        QString binForm,
        bool check = true)
{
    QStandardItem* item = new QStandardItem(instName + " " + args); item->setEditable(false);
    model->setItem(row, 0, item);
    model->setItem(row, 1, new QStandardItem(instName));
    model->setItem(row, 2, new QStandardItem(opcode));

    if (binForm == "R") model->setItem(row, 3, new QStandardItem(funct));
    else
    {
        QStandardItem* item = new QStandardItem(args.isEmpty() ? "" : "0 (使わない)");
        item->setEditable(false);
        model->setItem(row, 3, item);
    }

    if (useCheckBox)
    {
        QStandardItem* item0 = new QStandardItem(true);
        item0->setEditable(false);
        item0->setCheckable(true);
        if (check)
        {
            item0->setCheckState(Qt::Checked);
        }
        else
        {
            item0->setCheckState(Qt::Unchecked);
        }
        model->setItem(row, 4, item0);
    }
    else
    {
        QStandardItem* item1 = new QStandardItem("必須");
        item1->setEditable(false);
        model->setItem(row, 4, item1);
    }

    item = new QStandardItem(code); item->setEditable(false);
    item->setEditable(false);
    model->setItem(row, 5, item);
    item = new QStandardItem(binForm); item->setEditable(false);
    item->setEditable(false);
    model->setItem(row, 6, item);
}

void MainWindow::InitInstTVs()
{
    int cnt = 0;
    QStringList instHHeader;
    instHHeader
        << "アセンブリ形式"
        << "命令名"
        << "opcode\n(6桁以内の2進数\nまたはバイナリ定数)"
        << "funct\n(6桁以内の2進数)"
        << "この命令使う？"
        << "擬似コード"
        << "バイナリ形式";

    //
    // バイナリ(opcode)定数
    //
    QStandardItemModel* tableModel = new QStandardItemModel();
    constModel = tableModel;
    cnt = 0;
    tableModel->setItem(cnt, 0, new QStandardItem("ALU"));
    tableModel->setItem(cnt++, 1, new QStandardItem("0"));
    tableModel->setItem(cnt, 0, new QStandardItem("FPU"));
    tableModel->setItem(cnt++, 1, new QStandardItem("1"));
    tableModel->setItem(cnt, 0, new QStandardItem("Move"));
    tableModel->setItem(cnt++, 1, new QStandardItem("10"));
    tableModel->setItem(cnt, 0, new QStandardItem("System"));
    tableModel->setItem(cnt++, 1, new QStandardItem("11"));
    QStringList constHeader;
    constHeader << "定数名" << "値\n(6桁以内の2進数)";
    tableModel->setHorizontalHeaderLabels(constHeader);
    ui->ConstTV->setModel(tableModel);
    ui->ConstTV->resizeColumnsToContents();
    ui->ConstTV->resizeRowsToContents();

    //
    // 整数演算1
    //
    tableModel = new QStandardItemModel();
    int1Model = tableModel;
    int1Expalains.clear();
    int1Expalains
        << "値の複製"
        << "たし算"
        << "ひき算"
        << "かけ算"
        << "わり算"
        << "論理左シフト"
        << "論理右シフト"
        << "算術左シフト"
        << "算術右シフト"
        << "論理シフト\n(値に応じて左右切替)"
        << "論理積"
        << "論理和"
        << "論理否定和"
        << "排他的論理和"
        << "ビット反転";
    cnt = 0;
    AddRow(tableModel, cnt++, "mov", true, "rt, rs", "Move", "0", "rt <- rs", "R", false);
    ADD_ROW = cnt;
    AddRow(tableModel, cnt++, "add", false, "rd, rs, rt", "ALU", "0", "rd <- rs + rt", "R");
    SUB_ROW = cnt;
    AddRow(tableModel, cnt++, "sub", false, "rd, rs, rt", "ALU", "1","rd <- rs - rt", "R");
    AddRow(tableModel, cnt++, "mul", true, "rd, rs, rt", "ALU", "10","rd <- rs * rt", "R");
    AddRow(tableModel, cnt++, "div", true, "rd, rs, rt", "ALU", "11","rd <- rs / rt", "R", false);
    AddRow(tableModel, cnt++, "sll", true, "rd, rs, rt", "ALU", "100","rd <- rs << rt", "R", false);
    AddRow(tableModel, cnt++, "srl", true, "rd, rs, rt", "ALU", "101","rd <- rs >> rt", "R", false);
    AddRow(tableModel, cnt++, "sla", true, "rd, rs, rt", "ALU", "110","rd <- rs << rt", "R", false);
    AddRow(tableModel, cnt++, "sra", true, "rd, rs, rt", "ALU", "111","rd <- rs >> rt", "R", false);
    AddRow(tableModel, cnt++, "shift", true, "rd, rs, rt", "ALU", "1000","rd <- rs shift rt", "R", false);
    AddRow(tableModel, cnt++, "and", true, "rd, rs, rt", "ALU", "1001","rd <- rs & rt", "R");
    AddRow(tableModel, cnt++, "or", true, "rd, rs, rt", "ALU", "1010","rd <- rs | rt", "R");
    NOR_ROW = cnt;
    AddRow(tableModel, cnt++, "nor", true, "rd, rs, rt", "ALU", "1011","rd <- rs nor rt", "R");
    AddRow(tableModel, cnt++, "xor", true, "rd, rs, rt", "ALU", "1100","rd <- rs xor rt", "R");
    AddRow(tableModel, cnt++, "not", true, "rt, rs", "ALU", "1101","rt <- not rs", "R");
    tableModel->setHorizontalHeaderLabels(instHHeader);
    tableModel->setVerticalHeaderLabels(int1Expalains);
    ui->IntTV1->setModel(tableModel);
    ui->IntTV1->resizeColumnsToContents();
    ui->IntTV1->resizeRowsToContents();

    //
    // 整数演算2
    //
    tableModel = new QStandardItemModel();
    int2Model = tableModel;
    int2Expalains.clear();
    int2Expalains
        << "下位16bitに即値代入"
        << "上位16bitに即値代入"
        << "たし算"
        << "ひき算"
        << "かけ算"
        << "わり算"
        << "論理左シフト"
        << "論理右シフト"
        << "算術左シフト"
        << "算術右シフト"
        << "論理シフト\n(値に応じて左右切替)"
        << "論理積"
        << "論理和"
        << "論理否定和"
        << "排他的論理和";
    cnt = 0;
    AddRow(tableModel, cnt++, "mvlo", false, "rs, imm", "10001", "0","rs[0:15] <- imm", "I");
    AddRow(tableModel, cnt++, "mvhi", false, "rs, imm", "10010", "0","rs[16:31] <- imm", "I");
    ADDI_ROW = cnt;
    AddRow(tableModel, cnt++, "addi", true, "rt, rs, imm", "100", "0","rt <- rs + imm", "I");
    AddRow(tableModel, cnt++, "subi", true, "rt, rs, imm", "101", "0","rt <- rs - imm", "I");
    AddRow(tableModel, cnt++, "muli", true, "rt, rs, imm", "110", "0","rt <- rs * imm", "I");
    AddRow(tableModel, cnt++, "divi", true, "rt, rs, imm", "111", "0","rt <- rs / imm", "I", false);
    AddRow(tableModel, cnt++, "slli", false, "rt, rs, imm", "1000", "0","rt <- rs << imm", "I");
    AddRow(tableModel, cnt++, "srli", true, "rt, rs, imm", "1001", "0","rt <- rs >> imm", "I", false);
    AddRow(tableModel, cnt++, "slai", true, "rt, rs, imm", "1010", "0", "rt <- rs << imm", "I", false);
    AddRow(tableModel, cnt++, "srai", false, "rt, rs, imm", "1011", "0", "rt <- rs >> imm", "I");
    AddRow(tableModel, cnt++, "shifti", true, "rt, rs, imm", "1100", "0","rt <- rs shift imm", "I", false);
    AddRow(tableModel, cnt++, "andi", true, "rt, rs, imm", "1101", "0","rt <- rs & imm", "I");
    AddRow(tableModel, cnt++, "ori", true, "rt, rs, imm", "1110", "0","rt <- rs | imm", "I");
    AddRow(tableModel, cnt++, "nori", true, "rt, rs, imm", "1111", "0","rt <- rs nor imm", "I");
    AddRow(tableModel, cnt++, "xori", true, "rt, rs, imm", "10000", "0","rt <- rs xor imm", "I");
    tableModel->setHorizontalHeaderLabels(instHHeader);
    tableModel->setVerticalHeaderLabels(int2Expalains);
    ui->IntTV2->setModel(tableModel);
    ui->IntTV2->resizeColumnsToContents();
    ui->IntTV2->resizeRowsToContents();

    //
    // 浮動小数演算
    //
    tableModel = new QStandardItemModel();
    floatModel = tableModel;
    floatExpalains.clear();
    floatExpalains
        << "値の複製"
        << "符号反転"
        << "下位16bitに即値代入"
        << "上位16bitに即値代入"
        << "たし算"
        << "ひき算"
        << "かけ算"
        << "かけ算して符号反転"
        << "わり算"
        << "逆数"
        << "逆数のマイナス"
        << "絶対値"
        << "平方根"
        << "切り捨て"
        << "正弦"
        << "余弦"
        << "正接"
        << "逆正接";
    cnt = 0;
    AddRow(tableModel, cnt++, "fmov", false, "frt, frs", "Move", "1","frt <- frs", "R");
    AddRow(tableModel, cnt++, "fneg", false, "frt, frs", "FPU", "0","frt <- -frs", "R");
    FSETLO_ROW = cnt;
    AddRow(tableModel, cnt++, "fmvlo", true, "frs, imm", "10011", "0","frs[0:15] <- imm", "I");
    FSETHI_ROW = cnt;
    AddRow(tableModel, cnt++, "fmvhi", true, "frs, imm", "10100", "0","frs[16:31] <- imm", "I");
    AddRow(tableModel, cnt++, "fadd", false, "frd, frs, frt", "FPU", "1","frd <- frs + frt", "R");
    AddRow(tableModel, cnt++, "fsub", false, "frd, frs, frt", "FPU", "10","frd <- frs - frt", "R");
    AddRow(tableModel, cnt++, "fmul", false, "frd, frs, frt", "FPU", "11","frd <- frs * frt", "R");
    AddRow(tableModel, cnt++, "fmuln", true, "frd, frs, frt", "FPU", "100", "frd <- -(frs * frt)", "R");
    // 以下2つは排他的に選択される
    AddRow(tableModel, cnt++, "fdiv", false, "frd, frs, frt", "FPU", "101","frd <- frs / frt", "R");
    AddRow(tableModel, cnt++, "finv", true, "frt, frs", "FPU", "110","frt <- 1 / frs", "R", false);
    AddRow(tableModel, cnt++, "finvn", true, "frt, frs", "FPU", "111","frt <- - 1 / frs", "R", false);
    AddRow(tableModel, cnt++, "fabs", true, "frt, frs", "FPU", "1000", "frt <- fabs(frs)", "R", false);
    AddRow(tableModel, cnt++, "fsqrt", false, "frt, frs", "FPU", "1001", "frt <- fsqrt(frs)", "R");
    AddRow(tableModel, cnt++, "floor", true, "frt, frs", "FPU", "1010", "frt <- floor(frs)", "R", false);
    AddRow(tableModel, cnt++, "fsin", true, "frt, frs", "FPU", "1011", "frt <- fsin(frs)", "R", false);
    AddRow(tableModel, cnt++, "fcos", true, "frt, frs", "FPU", "1100", "frt <- fcos(frs)", "R", false);
    AddRow(tableModel, cnt++, "ftan", true, "frt, frs", "FPU", "1101", "frt <- ftan(frs)", "R", false);
    AddRow(tableModel, cnt++, "fatan", true, "frt, frs", "FPU", "1110", "frt <- fatan(frs)", "R", false);
    tableModel->setHorizontalHeaderLabels(instHHeader);
    tableModel->setVerticalHeaderLabels(floatExpalains);
    ui->FloatTV->setModel(tableModel);
    ui->FloatTV->resizeColumnsToContents();
    ui->FloatTV->resizeRowsToContents();

    //
    // 整数・浮動小数変換
    //
    tableModel = new QStandardItemModel();
    ifconvModel = tableModel;
    ifconvExpalains.clear();
    ifconvExpalains
        << "intをfloatにキャスト"
        << "floatをintにキャスト"
        << "バイナリ列をコピー"
        << "バイナリ列をコピー";
    cnt = 0;
    AddRow(tableModel, cnt++, "itof", true, "frt, rs", "Move", "10", "frt <- (float)rs", "R");
    AddRow(tableModel, cnt++, "ftoi", true, "rt, frs", "Move", "11", "rt <- (int)frs", "R");
    AddRow(tableModel, cnt++, "imovf", true, "frt, rs", "Move", "100", "frt <- rs", "R");
    AddRow(tableModel, cnt++, "fmovi", true, "rt, frs", "Move", "101", "rt <- frs", "R");
    tableModel->setHorizontalHeaderLabels(instHHeader);
    tableModel->setVerticalHeaderLabels(ifconvExpalains);
    ui->IFConvTV->setModel(tableModel);
    ui->IFConvTV->resizeColumnsToContents();
    ui->IFConvTV->resizeRowsToContents();

    //
    // メモリアクセス
    //
    tableModel = new QStandardItemModel();
    memoryModel = tableModel;
    memoryExpalains.clear();
    memoryExpalains
        << "メモリから整数レジスタへロード"
        << "整数レジスタをメモリへストア"
        << "メモリから整数レジスタへロード"
        << "整数レジスタをメモリへストア"
        << "メモリから浮動小数レジスタへロード"
        << "浮動小数レジスタをメモリへストア"
        << "メモリから浮動小数レジスタへロード"
        << "浮動小数レジスタをメモリへストア";
    cnt = 0;
    AddRow(tableModel, cnt++, "ldi", false, "rt, rs, imm", "101000", "0","rt <- RAM[rs + imm]", "I");
    AddRow(tableModel, cnt++, "sti", false, "rt, rs, imm", "101001", "0","RAM[rs + imm] <- rt", "I");
    AddRow(tableModel, cnt++, "ldr", true, "rd, rs, rt", "ALU", "1110", "rd <- RAM[rs + rt]", "R");
    AddRow(tableModel, cnt++, "str", true, "rd, rs, rt", "ALU", "1111", "RAM[rs + rt] <- rd", "R");
    AddRow(tableModel, cnt++, "fldi", false, "frt, rs, imm", "101010", "0", "frt <- RAM[rs + imm]", "I");
    AddRow(tableModel, cnt++, "fsti", false, "frt, rs, imm", "101011", "0", "RAM[rs + imm] <- frt", "I");
    AddRow(tableModel, cnt++, "fldr", true, "frd, rs, rt", "ALU", "10000","frd <- RAM[rs + rt]", "R");
    AddRow(tableModel, cnt++, "fstr", true, "frd, rs, rt", "ALU", "10001", "RAM[rs + rt] <- frd", "R");
    tableModel->setHorizontalHeaderLabels(instHHeader);
    tableModel->setVerticalHeaderLabels(memoryExpalains);
    ui->MemoryTV->setModel(tableModel);
    ui->MemoryTV->resizeColumnsToContents();
    ui->MemoryTV->resizeRowsToContents();


    //
    // 分岐・ジャンプ
    //
    tableModel = new QStandardItemModel();
    branchModel = tableModel;
    branchExpalains.clear();
    branchExpalains
        << "等しい"
        << "等しくない"
        << "より小さい"
        << "より大きい"
        << "以下"
        << "以上"
        << "等しい"
        << "等しくない"
        << "より小さい"
        << "より大きい"
        << "以下"
        << "以上"
        << "ラベルへジャンプ"
        << "レジスタ値へジャンプ"
        << "低機能な関数呼び出し方式"
        << "リンクしてラベルへジャンプ"
        << "リンクしてレジスタ値へジャンプ"
        << "高機能な関数呼び出し方式（コアが大変？）"
        << "フレームポインタを減らして\nリンクしてラベルへジャンプ"
        << "フレームポインタを減らして\nリンクしてレジスタ値へジャンプ"
        << "フレームポインタを増やして\nリンクレジスタの値へジャンプ";
    cnt = 0;
    AddRow(tableModel, cnt++, "beq", false, "rs, rt, imm", "10110", "0", "if rs == rt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "bne", true, "rs, rt, imm", "10111", "0", "if rs != rt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "blt", false, "rs, rt, imm", "11000", "0", "if rs < rt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "bgt", true, "rs, rt, imm", "11001", "0", "if rs > rt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "ble", true, "rs, rt, imm", "11010", "0", "if rs <= rt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "bge", true, "rs, rt, imm", "11011", "0", "if rs >= rt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "fbeq", false, "frs, frt, imm", "11100", "0", "if frs == frt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "fbne", true, "frs, frt, imm", "11101", "0", "if frs != frt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "fblt", false, "frs, frt, imm", "11110", "0", "if frs < frt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "fbgt", true, "frs, frt, imm", "11111", "0", "if frs > frt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "fble", true, "frs, frt, imm", "100000", "0", "if frs <= frt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "fbge", true, "frs, frt, imm", "100001", "0", "if frs >= frt then goto (pc + imm)", "I");
    AddRow(tableModel, cnt++, "j", false, "labelName", "10101", "0", "goto labelName", "J");
    AddRow(tableModel, cnt++, "jr", false, "rs", "100010", "0", "goto rs", "R");
    // 低・高機能は排他的に
    LOW_CALL = cnt;
    AddRow(tableModel, cnt++, "", true, "", "", "",  "", "");
    AddRow(tableModel, cnt++, "jal", false, "labelName", "100011", "0", "link register <- pc; goto labelName", "J");
    AddRow(tableModel, cnt++, "jalr", false, "rs", "100100", "0", "link register <- pc; goto rs", "R");
    HIGH_CALL = cnt;
    AddRow(tableModel, cnt++, "", true, "", "", "",  "", "");
    AddRow(tableModel, cnt++, "call", false, "labelName", "100101", "0", "RAM[frame pointer] <- link register\nframe pointer--\nlink register <- pc; goto labelName", "J");
    AddRow(tableModel, cnt++, "callr", false, "reg", "100110", "0","RAM[frame pointer] <- link register\nframe pointer--\nlink register <- pc; goto rs", "R");
    AddRow(tableModel, cnt++, "return", false, "op", "100111", "0", "RAM[frame pointer] <- link register\nframe pointer++\ngoto link register", "R");
    tableModel->setHorizontalHeaderLabels(instHHeader);
    tableModel->setVerticalHeaderLabels(branchExpalains);
    ui->BranchTV->setModel(tableModel);
    ui->BranchTV->resizeColumnsToContents();
    ui->BranchTV->resizeRowsToContents();

    //
    // 入力
    //
    tableModel = new QStandardItemModel();
    ioModel = tableModel;
    ioExpalains.clear();
    ioExpalains
        <<"1byte読み込み"
        <<"1word読み込み"
        <<"1byte浮動小数レジスタに読み込み"
        <<"1byte書き出し"
        <<"1word書き出し"
        <<"1byte浮動小数レジスタから書き出し"
        <<"プログラムを終了";
    cnt = 0;
    AddRow(tableModel, cnt++, "inputb", false, "rs", "System", "0","rs <- ReadByte()", "R");
    AddRow(tableModel, cnt++, "inputw", true, "rs", "System", "1","rs <- ReadWord()", "R");
    AddRow(tableModel, cnt++, "inputf", true, "frs", "System", "10","frs <- ReadWord()", "R");
    AddRow(tableModel, cnt++, "outputb", false, "rs", "System", "11","WriteByte(rs & 0xf)", "R");
    AddRow(tableModel, cnt++, "outputw", true, "rs", "System", "100","WriteWord(rs)", "R");
    AddRow(tableModel, cnt++, "outputf", true, "frs", "System", "101","WriteWord(frs)", "R");
    AddRow(tableModel, cnt++, "halt", false, " ", "System", "110", "", "R");
    tableModel->setHorizontalHeaderLabels(instHHeader);
    tableModel->setVerticalHeaderLabels(ioExpalains);
    ui->IOTV->setModel(tableModel);
    ui->IOTV->resizeColumnsToContents();
    ui->IOTV->resizeRowsToContents();
}

void MainWindow::ChangeRegName(int row, int index, QStringList& iregs)
{
    if (index < 0) index = 0;
    if (index >= iregs.length()) index = iregs.length() - 1;
    ComboBoxDelegate* cdel = (ComboBoxDelegate*)ui->GeneralTV->itemDelegateForRow(row);
    cdel->itemList = iregs;
    ui->GeneralTV->setItemDelegateForRow(row, cdel);
    generalModel->setItem(row, new QStandardItem(iregs[index]));
}

void MainWindow::ChangeRegNames(QStandardItem *item)
{
//    if (item->row() != IREG_PREFIX) return;

    disconnect(generalModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeRegNames(QStandardItem*)));
    int zr_index = GetRegIndex(generalModel->item(ZR)->text());
    int fr_index = GetRegIndex(generalModel->item(FR)->text());
    int hr_index = GetRegIndex(generalModel->item(HR)->text());
    int lr_index = GetRegIndex(generalModel->item(LR)->text()) + 1;
    int p1r_index = GetRegIndex(generalModel->item(P1R)->text());
    int m1r_index = GetRegIndex(generalModel->item(M1R)->text());
    UpdateRegisters();
    ChangeRegName(ZR, zr_index, iregs);
    ChangeRegName(FR, fr_index, iregs);
    ChangeRegName(HR, hr_index, iregs);
    ChangeRegName(LR, lr_index, QStringList("専用のレジスタを使用") << iregs);
    ChangeRegName(P1R, p1r_index, iregs);
    ChangeRegName(M1R, m1r_index, iregs);
    connect(generalModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeRegNames(QStandardItem*)));
}

void MainWindow::ToggleCallMode(QStandardItem* item)
{
 //   disconnect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ToggleCallMode(QStandardItem*)));
 //   disconnect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    bool lowCell = item->column() == 4 && item->row() == LOW_CALL;
    bool highCell = item->column() == 4 && item->row() == HIGH_CALL;
    bool check = item->checkState() == Qt::Checked;
    bool isLow = (lowCell && check) || (highCell && !check);
    bool isHigh = (lowCell && !check) || (highCell && check);
    if (!isLow && !isHigh) return;
    branchModel->item(LOW_CALL, 4)->setCheckState(isLow ? Qt::Checked : Qt::Unchecked);
    for (int i = LOW_CALL + 1; i <= LOW_CALL + 2; i++)
    {
        branchModel->setItem(i, 4, new QStandardItem(isLow ? "必須" : "使わない"));
    }
    branchModel->item(HIGH_CALL, 4)->setCheckState(!isLow ? Qt::Checked : Qt::Unchecked);
    for (int i = HIGH_CALL + 1; i <= HIGH_CALL + 3; i++)
    {
        branchModel->setItem(i, 4, new QStandardItem(!isLow ? "必須" : "使わない"));
    }
 //   connect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
 //   connect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ToggleCallMode(QStandardItem*)));
}

// 命令名が変わったら「アセンブリ形式」を修正
void MainWindow::ChangeAsmForm(QStandardItem* item)
{
//    disconnect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ToggleCallMode(QStandardItem*)));
  //  disconnect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    QStandardItemModel* model = item->model();
    int row = item->row();
    int col = item->column();
    if (col != 1) return;
    QString text = model->item(row, 0)->text();
    int len = text.split(' ')[0].length();
    model->item(row, 0)->setText(text.replace(0, len, model->item(row, 1)->text()));
//    connect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
  //  connect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ToggleCallMode(QStandardItem*)));
}

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    setWindowTitle("CPUExSolver2");
    InitGeneralTV();
    InitInstTVs();
    connect(generalModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeRegNames(QStandardItem*)));
    connect(int1Model, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    connect(int2Model, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    connect(floatModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    connect(ifconvModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    connect(memoryModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    connect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    connect(ioModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ChangeAsmForm(QStandardItem*)));
    connect(branchModel, SIGNAL(itemChanged(QStandardItem*)), this, SLOT(ToggleCallMode(QStandardItem*)));
    branchModel->item(LOW_CALL, 4)->setCheckState(Qt::Unchecked);
}

MainWindow::~MainWindow()
{
    delete ui;
}

int MainWindow::GetRegIndex(QString str)
{
    for (int i = 0; i < iregs.length(); i++)
    {
        if (iregs[i] == str) return i;
    }
    return -1;
}

QString MainWindow::GetInstTag(QStandardItemModel* model, int row, QString type, bool relativeAddress, bool isUse)
{
    QString use = isUse ? "" : " use=\"false\"";
    QString name = " name=\"" + model->item(row, 1)->text() + "\"";
    QString addressMode = "";
    if (relativeAddress) addressMode = " addressMode=\"relative\"";
    QString op = model->item(row, 2)->text();
    QString funct = op[0].isDigit() ? "" : " funct=\"0b" + model->item(row, 3)->text() + "\"";
    op = " op=\"" + (op[0].isDigit() ? "0b" + op : op) + "\"";
    return "\t\t<" + type + use + name + op + funct + addressMode + "/>\n";
}

QString MainWindow::GetInstTag(QStandardItemModel* model, int row, QString type, bool relativeAddress)
{
    bool use =  model->item(row, 4)->text() == "必須" || model->item(row, 4)->checkState() == Qt::Checked;
    return GetInstTag(model, row, type, relativeAddress, use);
}

// 設定ファイルを生成
bool MainWindow::WriteXML(QString filepath)
{
    QFile file(filepath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text) == false)
    {
        QMessageBox::critical(NULL, "書き込みエラー", "設定ファイルの書き込みに失敗しました", QMessageBox::Ok);
        return false;
    }

    QTextStream out(&file);
    out.setCodec("UTF-8");

    QString consts;
    for (int i = 0; i < constModel->rowCount(); i++)
    {
        QString name = constModel->item(i, 0)->text();
        QString value = constModel->item(i, 1)->text();
        if (name != "" && value != "")
        {
            consts += "\t\t\t<" + name + " value=\"0b" + value + "\"/>\n";
        }
    }

    QString r = "$" + generalModel->item(IREG_PREFIX)->text().trimmed();
    QString f = "$" + generalModel->item(FREG_PREFIX)->text().trimmed();
    QString tmp;
    int zr_index = GetRegIndex(generalModel->item(ZR)->text());
    int fr_index = GetRegIndex(generalModel->item(FR)->text());
    int hr_index = GetRegIndex(generalModel->item(HR)->text());
    int lr_index = GetRegIndex(generalModel->item(LR)->text());
    int p1r_index = GetRegIndex(generalModel->item(P1R)->text());
    int m1r_index = GetRegIndex(generalModel->item(M1R)->text());
    QString endian = generalModel->item(ENDIAN)->text().toInt() == 0 ? "LITTLE" : "BIG";
    QString ram_addressing = generalModel->item(RAM_ADDRESSING)->text().toInt() == 0 ? "word" : "byte";
    QString rom_addressing = generalModel->item(ROM_ADDRESSING)->text().toInt() == 0 ? "word" : "byte";

    QString add = int1Model->item(ADD_ROW, 1)->text();
    QString sub = int1Model->item(SUB_ROW, 1)->text();
    QString nor = int1Model->item(NOR_ROW, 1)->text();
    QString addi = int2Model->item(ADDI_ROW, 1)->text();
    QString fsetlo = floatModel->item(FSETLO_ROW, 1)->text();
    QString fsethi = floatModel->item(FSETHI_ROW, 1)->text();

    // inst sets
    QString insts;
    int row = 0;
    insts += GetInstTag(int1Model, row++, "MOV", false);
    insts += GetInstTag(int1Model, row++, "ADD", false);
    insts += GetInstTag(int1Model, row++, "SUB", false);
    insts += GetInstTag(int1Model, row++, "MUL", false);
    insts += GetInstTag(int1Model, row++, "DIV", false);
    insts += GetInstTag(int1Model, row++, "SLL", false);
    insts += GetInstTag(int1Model, row++, "SRL", false);
    insts += GetInstTag(int1Model, row++, "SLA", false);
    insts += GetInstTag(int1Model, row++, "SRA", false);
    insts += GetInstTag(int1Model, row++, "SHIFT", false);
    insts += GetInstTag(int1Model, row++, "AND", false);
    insts += GetInstTag(int1Model, row++, "OR", false);
    insts += GetInstTag(int1Model, row++, "NOR", false);
    insts += GetInstTag(int1Model, row++, "XOR", false);
    insts += GetInstTag(int1Model, row++, "NOT", false);
    row = 0;
    insts += GetInstTag(int2Model, row++, "SETLO", false);
    insts += GetInstTag(int2Model, row++, "SETHI", false);
    insts += GetInstTag(int2Model, row++, "ADDI", false);
    insts += GetInstTag(int2Model, row++, "SUBI", false);
    insts += GetInstTag(int2Model, row++, "MULI", false);
    insts += GetInstTag(int2Model, row++, "DIVI", false);
    insts += GetInstTag(int2Model, row++, "SLLI", false);
    insts += GetInstTag(int2Model, row++, "SRLI", false);
    insts += GetInstTag(int2Model, row++, "SLAI", false);
    insts += GetInstTag(int2Model, row++, "SRAI", false);
    insts += GetInstTag(int2Model, row++, "SHIFTI", false);
    insts += GetInstTag(int2Model, row++, "ANDI", false);
    insts += GetInstTag(int2Model, row++, "ORI", false);
    insts += GetInstTag(int2Model, row++, "NORI", false);
    insts += GetInstTag(int2Model, row++, "XORI", false);
    row = 0;
    insts += GetInstTag(floatModel, row++, "FMOV", false);
    insts += GetInstTag(floatModel, row++, "FNEG", false);
    insts += GetInstTag(floatModel, row++, "FSETLO", false);
    insts += GetInstTag(floatModel, row++, "FSETHI", false);
    insts += GetInstTag(floatModel, row++, "FADD", false);
    insts += GetInstTag(floatModel, row++, "FSUB", false);
    insts += GetInstTag(floatModel, row++, "FMUL", false);
    insts += GetInstTag(floatModel, row++, "FMULN", false);
    insts += GetInstTag(floatModel, row++, "FDIV", false);
    insts += GetInstTag(floatModel, row++, "FINV", false);
    insts += GetInstTag(floatModel, row++, "FINVN", false);
    insts += GetInstTag(floatModel, row++, "FABS", false);
    insts += GetInstTag(floatModel, row++, "FSQRT", false);
    insts += GetInstTag(floatModel, row++, "FLOOR", false);
    insts += GetInstTag(floatModel, row++, "FSIN", false);
    insts += GetInstTag(floatModel, row++, "FCOS", false);
    insts += GetInstTag(floatModel, row++, "FTAN", false);
    insts += GetInstTag(floatModel, row++, "FATAN", false);
    row = 0;
    insts += GetInstTag(ifconvModel, row++, "ITOF", false);
    insts += GetInstTag(ifconvModel, row++, "FTOI", false);
    insts += GetInstTag(ifconvModel, row++, "IMOVF", false);
    insts += GetInstTag(ifconvModel, row++, "FMOVI", false);
    row = 0;
    insts += GetInstTag(memoryModel, row++, "LDI", false);
    insts += GetInstTag(memoryModel, row++, "STI", false);
    insts += GetInstTag(memoryModel, row++, "LD", false);
    insts += GetInstTag(memoryModel, row++, "ST", false);
    insts += GetInstTag(memoryModel, row++, "FLDI", false);
    insts += GetInstTag(memoryModel, row++, "FSTI", false);
    insts += GetInstTag(memoryModel, row++, "FLD", false);
    insts += GetInstTag(memoryModel, row++, "FST", false);
    row = 0;
    insts += GetInstTag(branchModel, row++, "BEQ", true);
    insts += GetInstTag(branchModel, row++, "BNE", true);
    insts += GetInstTag(branchModel, row++, "BLT", true);
    insts += GetInstTag(branchModel, row++, "BGT", true);
    insts += GetInstTag(branchModel, row++, "BLE", true);
    insts += GetInstTag(branchModel, row++, "BGE", true);
    insts += GetInstTag(branchModel, row++, "FBEQ", true);
    insts += GetInstTag(branchModel, row++, "FBNE", true);
    insts += GetInstTag(branchModel, row++, "FBLT", true);
    insts += GetInstTag(branchModel, row++, "FBGT", true);
    insts += GetInstTag(branchModel, row++, "FBLE", true);
    insts += GetInstTag(branchModel, row++, "FBGE", true);
    insts += GetInstTag(branchModel, row++, "BRANCH", false);
    insts += GetInstTag(branchModel, row++, "JMPREG", false);
    // jalを使う関数呼び出しとcallを使う呼び出しは排他的に選択
    bool use = branchModel->item(row, 4)->checkState() == Qt::Checked;
    row++;
    insts += GetInstTag(branchModel, row++, "JMP_LNK", false, use);
    insts += GetInstTag(branchModel, row++, "JMPREG_LNK", false, use);
    row++;
    insts += GetInstTag(branchModel, row++, "CALL", false, !use);
    insts += GetInstTag(branchModel, row++, "CALLREG", false, !use);
    insts += GetInstTag(branchModel, row++, "RETURN", false, !use);
    row = 0;
    insts += GetInstTag(ioModel, row++, "INPUTBYTE", false);
    insts += GetInstTag(ioModel, row++, "INPUTWORD", false);
    insts += GetInstTag(ioModel, row++, "INPUTFLOAT", false);
    insts += GetInstTag(ioModel, row++, "OUTPUTBYTE", false);
    insts += GetInstTag(ioModel, row++, "OUTPUTWORD", false);
    insts += GetInstTag(ioModel, row++, "OUTPUTFLOAT", false);
    insts += GetInstTag(ioModel, row++, "HALT", false);

    // QStringでくくると日本語もいい感じに表示されるっぽい
    out     << "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"
            << "<architecture name=\"" << generalModel->item(ARCHITECTURE)->text() << "\">\n"
            << "\t<registers>\n"
            << QString("\t\t<!-- %は特殊文字として扱われるためとして%%とエスケープする -->\n")
            << "\t\t<intRegs num=\"" << generalModel->item(IREG_NUM)->text() << "\" prefix=\"" << r << "\"/>\n"
            << "\t\t<floatRegs num=\"" << generalModel->item(FREG_NUM)->text() << "\" prefix=\"" << f << "\"/>\n"
            << "\t\t<constFloatRegs num=\"" << generalModel->item(CACHE_NUM)->text() << "\"/>\n"
            << "\t\t<zeroReg index=\"" <<  zr_index << "\"/>\n"
            << "\t\t<frameReg index=\"" << fr_index << "\"/>\n"
            << "\t\t<heapReg index=\"" << hr_index << "\"/>\n"
            << "\t\t<oneReg index=\"" << p1r_index << "\"/>\n"
            << "\t\t<minusOneReg index=\"" << m1r_index << "\"/>\n"
            << QString("\t\t<!-- indexを\"\"にすると汎用レジスタとは別に用意されたレジスタが使われる -->\n")
            << "\t\t<linkReg index=\"" << (lr_index < 0 ? "" : tmp.number(lr_index)) << "\"/>\n"
            << "\t</registers>\n"
            << "\n"
            << "\t<RAM size=\"" << generalModel->item(RAM_SIZE)->text() << "\" />\n"
            << "\t<comment text=\"" << generalModel->item(COMMENTOUT)->text() << "\" />\n"
            << "\n"
            << "\t<binary endian=\"" << endian << "\" constTableType=\"no_use\" tag=\"0xffFFffFF\" addressing=\"" << ram_addressing << "\" rom_addressing=\"" << rom_addressing << "\" direction=\"toBig\"/>\n"
            << "\t<instructions forward=\"true\">\n"
            << "\t\t<CONST>\n"
            << consts
            << "\t\t</CONST>\n"
            << "\n"
            << insts
            << "\n"
            << "\t\t<mnemonics>\n"
            << "\t\t\t<NOP name=\"nop\" formAsm=\"\">\n"
            << "\t\t\t\t<inst command=\"&quot;" << add << "\\t" << r << "0, " << r << "0, " << r << "0&quot;\"/>\n"
            << "\t\t\t</NOP>\n"
            << "\t\t\t<MOV name=\"mov\" formAsm=\"IRT, IRS\">\n"
            << "\t\t\t\t<inst command=\"&quot;" << add << "\\t" << r << "%d, " << r << "%d, " << r << "0&quot;, rt, rs\"/>\n"
            << "\t\t\t</MOV>\n"
            << "\t\t\t<NOT name=\"not\" formAsm=\"IRT, IRS\">\n"
            << "\t\t\t\t<inst command=\"&quot;" << nor << "\\t" << r << "%d, " << r << "%d, " << r << "0&quot;, rt, rs, rs\" />\n"
            << "\t\t\t</NOT>\n"
            << "\t\t\t<NEG name=\"neg\" formAsm=\"IRT, IRS\">\n"
            << "\t\t\t\t<inst command=\"&quot;" << sub << "\\t" << r << "%d, " << r << "0, " << r << "%d&quot;, rt, rs\"/>\n"
            << "\t\t\t</NEG>\n"
            << "\t\t\t<SETL name=\"setl\" formAsm=\"IRS, LABEL\">\n"
            << "\t\t\t\t<inst useLabel=\"true\" command=\"&quot;" << addi << "\\t" << r << "%d, " << r << "0, 0&quot;, rs\"/>\n"
            << "\t\t\t</SETL>\n"
            << "\t\t\t<FSET name=\"fliw\" formAsm=\"FRS, FLOAT\">\n"
            << "\t\t\t\t<inst command=\"&quot;" << fsetlo << "\\t" << f << "%d, %d&quot;, rs, gethi(d)\"/>\n"
            << "\t\t\t\t<inst command=\"&quot;" << fsethi << "\\t" << f << "%d, %d&quot;, rs, getlo(d)\"/>\n"
            << "\t\t\t</FSET>\n"
            << "\t\t</mnemonics>\n"
            << "\t</instructions>\n"
            << "</architecture>\n";

    file.close();
    return true;
}

QString MainWindow::ReformBinaryValue(QString binVal, int length)
{
    const QString delimiter = "\t";
    if (binVal.isEmpty()) return binVal;
    int zeros = length - binVal.length();
    for (int i = 0; i < zeros; i++) binVal = "0" + binVal;
    for (int i = binVal.length() - 1; i > 0; i--) binVal.insert(i, delimiter);
    return binVal;
}

bool MainWindow::WriteTVsToCSV(QStandardItemModel* model, QStringList& explainList, QTextStream& out)
{
    const QString delimiter = "\t";
    for (int row = 0; row < model->rowCount(); row++)
    {
        if (model->item(row, 0)->text().trimmed().isEmpty()) continue;
        bool use =  model->item(row, 4)->text() == "必須" || model->item(row, 4)->checkState() == Qt::Checked;
        if (use == false) continue;
        QString name = model->item(row, 1)->text();
        QString explain = explainList[row].replace("\n", "");
        QString binForm = model->item(row, 6)->text();
        QString asmForm = model->item(row, 0)->text();
        QString code = model->item(row, 5)->text().replace("\n", "; ");
        QString op = model->item(row, 2)->text();
        if (IsConstBinaryName(op)) op = GetConstBinaryValue(op);
        QString funct = binForm == "R" ? model->item(row, 3)->text() : "";
        out << name << delimiter
            << explain << delimiter
            << binForm << delimiter
            << asmForm << delimiter
            << code << delimiter
            << ReformBinaryValue(op, BINARY_LENGTH) << delimiter
            << ReformBinaryValue(funct,BINARY_LENGTH) << "\n";
    }
    return true;
}


// アーキテクチャの仕様書を生成
// TODO
bool MainWindow::WriteCSV(QString filepath)
{
    const QString delimiter = "\t";
    QFile file(filepath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text) == false)
    {
        QMessageBox::critical(NULL, "書き込みエラー", "設定ファイルの書き込みに失敗しました", QMessageBox::Ok);
        return false;
    }
    QTextStream out(&file);
    out.setCodec("UTF-8");

    for (int row = 0; row < generalOptions.length(); row++)
    {
        out << generalOptions[row] << delimiter << generalModel->item(row)->text() << "\n";
    }

    out << "\n";
    out << "\n";

    out << QString("命令形式") << "\n";
    out << QString("R") << delimiter << "op(6bit)" << delimiter << "rs(5bit)" << delimiter << "rt(5bit)" << delimiter << "rd(5bit)" << delimiter << "shamt(5bit)"  << delimiter << "funct(5bit)" << "\n";
    out << QString("I") << delimiter << "op(6bit)" << delimiter << "rs(5bit)" << delimiter << "rt(5bit)" << delimiter << "imm(16bit)" << "\n";
    out << QString("J") << delimiter << "op(6bit)" << delimiter << "target(26bit)" << "\n";

    out << "\n";
    out << "\n";

    out << QString("命令名") << delimiter
        << QString("説明") << delimiter
        << QString("命令形式") << delimiter
        << QString("アセンブリ形式") << delimiter
        << QString("擬似コード") << delimiter
        << QString("op") << delimiter << delimiter << delimiter << delimiter << delimiter << delimiter
        << QString("funct") << "\n";

    WriteTVsToCSV(int1Model, int1Expalains, out);
    WriteTVsToCSV(int2Model, int2Expalains, out);
    WriteTVsToCSV(floatModel, floatExpalains, out);
    WriteTVsToCSV(ifconvModel, ifconvExpalains, out);
    WriteTVsToCSV(memoryModel, memoryExpalains, out);
    WriteTVsToCSV(branchModel, branchExpalains, out);
    WriteTVsToCSV(ioModel, ioExpalains, out);

    file.close();
    return true;
}

bool MainWindow::ErrorMsg(QString msg)
{
    QMessageBox::critical(NULL, "設定エラー", msg, QMessageBox::Ok);
    return false;
}

bool MainWindow::ValidString(QString str)
{
    if (str.length() <= 0) return false;
    for (int i = 0; i < str.length(); i++)
    {
        if ((str[i] < 'A' || 'z' < str[i]) && str[i] != '_') return false;
    }
    return true;
}

bool MainWindow::ValidBinary(QString str, int length)
{
    if (str.length() <= 0 || length < str.length()) return false;
    for (int i = 0; i < str.length(); i++)
    {
        if (str[i] != '1' && str[i] != '0') return false;
    }
    return true;
}

bool MainWindow::IsConstBinaryName(QString str)
{
    for (int row = 0; row < constModel->rowCount(); row++)
    {
        QString name = constModel->item(row, 0)->text();
        if (name == str) return true;
    }
    return false;
}

QString MainWindow::GetConstBinaryValue(QString str)
{
    for (int row = 0; row < constModel->rowCount(); row++)
    {
        QString name = constModel->item(row, 0)->text();
        if (name == str) return constModel->item(row, 1)->text();
    }
    return "";
}

void MainWindow::CheckModel(QStandardItemModel* model, QString tabName, QStringList explains, QHash<QString,QString>& binaryTable,bool& flg, QString& msg)
{
    QString tmp;
    const QString BINARY_LEN_STR = tmp.number(BINARY_LENGTH);
    for (int row = 0; row < model->rowCount(); row++)
    {
        if (model->item(row, 0)->text().trimmed().isEmpty()) continue;
        QString name = model->item(row, 1)->text();
        QString op = model->item(row, 2)->text();
        QString funct = model->item(row, 3)->isEditable() ? model->item(row, 3)->text() : "0";
        if (!ValidString(name))
        {
            flg = false;
            msg += tabName + "「" + explains[row] + "」: 命令名は半角アルファベットまたは_（アンダーバー）のみからなる文字列でなくてはいけません\n\n";
        }
        if (!IsConstBinaryName(op) && !ValidBinary(op, BINARY_LENGTH))
        {
            flg = false;
            msg += tabName + "「" + explains[row] + "」: opの値は" + BINARY_LEN_STR + "文字以下の2進数かバイナリ定数名でなくてはいけません\n\n";
        }
        if (!ValidBinary(funct, BINARY_LENGTH))
        {
            flg = false;
            msg += tabName + "「" + explains[row] + "」: functの値は" + BINARY_LEN_STR + "文字以下の2進数でなくてはいけません\n\n";
        }
        QString opbin = IsConstBinaryName(op) ? GetConstBinaryValue(op) : op;
        QString binary = opbin + "-" + funct;
        bool use =  model->item(row, 4)->text() == "必須" || model->item(row, 4)->checkState() == Qt::Checked;
        if (use)
        {
            if (binaryTable.contains(binary))
            {
                flg = false;
                msg += tabName + "「" + explains[row] + "」: op, functの値が" + binaryTable[binary] + " と同じです\n\n";
            }
            else
            {
                binaryTable[binary] = tabName + "「" + explains[row] + "」";
            }
        }
    }
}

bool MainWindow::CheckSettings()
{
    bool flg = true;
    QString msg = "";
    QString tmp;
    const QString BINARY_LEN_STR = tmp.number(BINARY_LENGTH);

    //
    // レジスタの接頭辞について
    //
    QString ireg_prefix = generalModel->item(IREG_PREFIX)->text();
    QString freg_prefix = generalModel->item(FREG_PREFIX)->text();
    if (ireg_prefix.isEmpty() || freg_prefix.isEmpty())
    {
        flg = false;
        msg += "レジスタの接頭辞は空文字列ではいけません\n\n";
    }
    if (ireg_prefix == freg_prefix)
    {
        flg = false;
        msg += "整数・浮動小数レジスタの接頭辞は互いに異なっていなくてはいけません\n\n";
    }
    if (!ValidString(ireg_prefix) || !ValidString((freg_prefix)))
    {
        flg = false;
        msg += "整数・浮動小数レジスタの接頭辞は半角アルファベットまたは_（アンダーバー）のみからなる文字列でなくてはいけません\n\n";
    }

    //
    // リンクレジスタについて
    //
    int lr_index = GetRegIndex(generalModel->item(LR)->text());
    if (lr_index < 0)
    {
        // jal使う時は専用レジスタは使えない
        if (branchModel->item(LOW_CALL, 4)->checkState() == Qt::Checked)
        {
            flg = false;
            msg += "低機能な関数呼び出しを使うとき、専用レジスタをリンクレジスタとして使うことはできません。\n\n";
        }
    }

    //
    // バイナリ定数について
    //
    for (int row = 0; row < constModel->rowCount(); row++)
    {
        QString name = constModel->item(row, 0)->text();
        QString value = constModel->item(row, 1)->text();
        if (!ValidString(name))
        {
            flg = false;
            msg += "バイナリ定数名は半角アルファベットまたは_（アンダーバー）のみからなる文字列でなくてはいけません\n\n";
        }
        if (!ValidBinary(value, BINARY_LENGTH))
        {
            flg = false;
            msg += "バイナリ定数の値は" + BINARY_LEN_STR + "文字以下の2進数でなくてはいけません\n\n";
        }
    }

    //
    // 各命令について
    //

    QHash<QString, QString> binaryTable;
    CheckModel(int1Model, "整数演算1", int1Expalains, binaryTable, flg, msg);
    CheckModel(int2Model, "整数演算2", int2Expalains, binaryTable, flg, msg);
    CheckModel(floatModel, "浮動小数演算", floatExpalains, binaryTable, flg, msg);
    CheckModel(ifconvModel, "整数・浮動小数変換", ifconvExpalains, binaryTable, flg, msg);
    CheckModel(memoryModel, "メモリアクセス", memoryExpalains, binaryTable, flg, msg);
    CheckModel(branchModel, "分岐・ジャンプ", branchExpalains, binaryTable, flg, msg);
    CheckModel(ioModel, "入出力", ioExpalains, binaryTable, flg, msg);

    if (flg == false)
    {
        return ErrorMsg(msg);
    }

    return true;
}

void MainWindow::CreateArchitecture()
{
    if (CheckSettings() == false) return;
    QString filepath = QFileDialog::getExistingDirectory(this, "アーキテクチャを作成場所を選んでください", ".");
    if (filepath == "" || !QDir(filepath).exists()) return;
    QString configFile = generalModel->item(ARCHITECTURE)->text() + ".xml";
    if (WriteXML("templates/" + configFile) == false) return;
    QString specFile = "specifications.csv.tmpl";
    if (WriteCSV("templates/" + specFile) == false) return;
    genDlg.Run("../" + configFile, filepath + "/" + generalModel->item(ARCHITECTURE)->text());
    genDlg.show();
}
