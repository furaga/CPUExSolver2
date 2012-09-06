#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QStandardItemModel>
#include <QItemDelegate>
#include "GenerateDialog.h"

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT
    
public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();
    
private:
    Ui::MainWindow *ui;
    QStringList iregs;
    QStringList fregs;
    QStandardItemModel* generalModel;
    QStandardItemModel* constModel;
    QStandardItemModel* int1Model;
    QStandardItemModel* int2Model;
    QStandardItemModel* floatModel;
    QStandardItemModel* ifconvModel;
    QStandardItemModel* memoryModel;
    QStandardItemModel* branchModel;
    QStandardItemModel* ioModel;
    QStringList generalOptions;
    QStringList int1Expalains;
    QStringList int2Expalains;
    QStringList floatExpalains;
    QStringList ifconvExpalains;
    QStringList memoryExpalains;
    QStringList branchExpalains;
    QStringList ioExpalains;
    // GeneralTableViewのデータ取得用
    static const int ARCHITECTURE = 0;
    static const int ENDIAN = 1;
    static const int ROM_SIZE = 2;
    static const int ROM_ADDRESSING = 3;
    static const int RAM_SIZE = 4;
    static const int RAM_ADDRESSING = 5;
    static const int COMMENTOUT = 6;
    static const int IREG_PREFIX = 7;
    static const int FREG_PREFIX = 8;
    static const int IREG_NUM = 9;
    static const int FREG_NUM = 10;
    static const int CACHE_NUM = 11;
    static const int ZR = 12;
    static const int FR = 13;
    static const int HR = 14;
    static const int LR = 15;
    static const int P1R = 16;
    static const int M1R = 17;
    static const int BINARY_LENGTH = 6;
    //
    int ADD_ROW;
    int SUB_ROW;
    int NOR_ROW;
    int ADDI_ROW;
    int FSETLO_ROW;
    int FSETHI_ROW;
    //
    int LOW_CALL;
    int HIGH_CALL;

    GenerateDialog genDlg;

    void UpdateRegisters();
    void AddRow(QStandardItemModel*, int, QString, bool, QString, QString, QString, QString, QString);
    void InitGeneralTV();
    void InitInstTVs();
    void ChangeRegName(int, int, QStringList&);
    int GetRegIndex(QString);
    QString GetInstTag(QStandardItemModel*, int, QString, bool, bool);
    QString GetInstTag(QStandardItemModel*, int, QString, bool);
    bool ValidString(QString);
    bool ValidBinary(QString, int);
    bool IsConstBinaryName(QString);
    QString GetConstBinaryValue(QString);
    bool ErrorMsg(QString);
    void CheckModel(QStandardItemModel*, QString, QStringList, QHash<QString,QString>&, bool&, QString&);
    bool CheckSettings();
    bool WriteXML(QString);
    QString ReformBinaryValue(QString, int);
    bool WriteTVsToCSV(QStandardItemModel*, QStringList&, QTextStream&);
    bool WriteCSV(QString);

private slots:

    void CreateArchitecture();
    void ChangeRegNames(QStandardItem* item);
    void ChangeAsmForm(QStandardItem* item);
    void ToggleCallMode(QStandardItem* item);
};

class ComboBoxDelegate : public QItemDelegate
{
    Q_OBJECT//マクロ
public:
    QStringList itemList;
    explicit ComboBoxDelegate(QObject *parent = 0);//コンストラクタ
    QWidget *createEditor(QWidget *parent, const QStyleOptionViewItem &option, const QModelIndex &index) const;
    void setEditorData(QWidget *editor, const QModelIndex &index) const;
    void setModelData(QWidget *editor, QAbstractItemModel *model, const QModelIndex &index) const;
    void updateEditorGeometry(QWidget *editor, const QStyleOptionViewItem &option, const QModelIndex &index) const;
};
class SpinBoxDelegate : public QItemDelegate
{
    Q_OBJECT//マクロ
public:
    int Max, Min;
    explicit SpinBoxDelegate(QObject *parent = 0);//コンストラクタ
    QWidget *createEditor(QWidget *parent, const QStyleOptionViewItem &option, const QModelIndex &index) const;
    void setEditorData(QWidget *editor, const QModelIndex &index) const;
    void setModelData(QWidget *editor, QAbstractItemModel *model, const QModelIndex &index) const;
    void updateEditorGeometry(QWidget *editor, const QStyleOptionViewItem &option, const QModelIndex &index) const;
};
class DoubleSpinBoxDelegate : public QItemDelegate
{
    Q_OBJECT//マクロ
public:
    double Max, Min;
    explicit DoubleSpinBoxDelegate(QObject *parent = 0);//コンストラクタ
    QWidget *createEditor(QWidget *parent, const QStyleOptionViewItem &option, const QModelIndex &index) const;
    void setEditorData(QWidget *editor, const QModelIndex &index) const;
    void setModelData(QWidget *editor, QAbstractItemModel *model, const QModelIndex &index) const;
    void updateEditorGeometry(QWidget *editor, const QStyleOptionViewItem &option, const QModelIndex &index) const;
};


#endif // MAINWINDOW_H
