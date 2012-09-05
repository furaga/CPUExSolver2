#include "GenerateDialog.h"
#include "ui_GenerateDialog.h"

GenerateDialog::GenerateDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::GenerateDialog)
{
    ui->setupUi(this);
    process = new QProcess(this);
    connect(process, SIGNAL(readyReadStandardOutput()), this, SLOT(updateOutput()));
    connect(process, SIGNAL(readyReadStandardError()), this, SLOT(updateError()));
    connect(process, SIGNAL(error(QProcess::ProcessError)), this, SLOT(processError(QProcess::ProcessError)));
    connect(process, SIGNAL(finished(int, QProcess::ExitStatus)), this, SLOT(proc_finished(int, QProcess::ExitStatus)));
}

GenerateDialog::~GenerateDialog()
{
    delete ui;
}

// エラーが出た
void GenerateDialog::processError(QProcess::ProcessError)
{

}

// ビルド系の初期化
void GenerateDialog::proc_finished(int, QProcess::ExitStatus stat)
{
    updateOutput();
    updateError();
    if (stat == QProcess::NormalExit) ui->label->setText("生成が完了しました");
    else ui->label->setText("生成中にエラーが発生しました");
    ui->CloseButton->setEnabled(true);
}

// 標準出力をテキストボックスに表示
void GenerateDialog::updateOutput()
{
    QByteArray output = process->readAllStandardOutput();
    QString str = QString::fromLocal8Bit(output);
    ui->textEdit->moveCursor(QTextCursor::End);
    ui->textEdit->insertPlainText(str);
}

// 標準エラーをテキストボックスに表示
void GenerateDialog::updateError()
{
    QByteArray output = process->readAllStandardError();
    QString str = QString::fromLocal8Bit(output);
    ui->textEdit->moveCursor(QTextCursor::End);
    ui->textEdit->insertPlainText(str);
}

void GenerateDialog::Run(QString configPath, QString dstPath)
{
    ui->label->setText("アーキテクチャを生成しています");
    process->setWorkingDirectory("templates");
    ui->textEdit->clear();
    ui->CloseButton->setEnabled(false);
    QStringList args;
    args
        << "CONFIGFILE=" + configPath
        << "DSTDIR=" + dstPath
        << "DSTDIR_TOP=" + dstPath;
    process->start("make", args);
}
