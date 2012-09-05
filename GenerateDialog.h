#ifndef GENERATEDIALOG_H
#define GENERATEDIALOG_H

#include <QDialog>
#include <QProcess>

namespace Ui {
class GenerateDialog;
}

class GenerateDialog : public QDialog
{
    Q_OBJECT
    
public:
    explicit GenerateDialog(QWidget *parent = 0);
    ~GenerateDialog();
    void Run(QString configPath, QString dstPath);

private:
    Ui::GenerateDialog *ui;
    QProcess* process;

private slots:
    void updateOutput();
    void updateError();
    void processError(QProcess::ProcessError err);
    void proc_finished(int ret, QProcess::ExitStatus stat);

};

#endif // GENERATEDIALOG_H
