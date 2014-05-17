using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using System.Security.Permissions;
using GeneralCtrlib;
using WFACaseTracerMS.IFaces;
using WFACaseTracerMS.Classes;

[assembly: StrongNameIdentityPermissionAttribute(SecurityAction.RequestMinimum, PublicKey = "0024000004800000940000000602000000240000525341310004000001000100c71c3f4452ab9b764d9601760f699f6515764a8e471c8eb8fdce25dc29e11fe9095e4f98ff8ca77edabb5136afd12db243f8b8b4a88c6a41b098f3450c9e8bb3edc50e0641ccd7e6cf005396a51e1b252749481a588714bc08e029b17eea87d9e4882670f82bcb75d099db688cc0c8e3f01be169254c671532001a47912396a9")] 
namespace WFACaseTracerMS
{
    /// <summary>
    /// 功能：病案移交：病案接收、发送、回退、及工作超限警示。
    ///  六个组都使用该窗口，但各用各的功能，相互依赖。
    /// </summary>
    public partial class CT_CaseDeliver : CT_BaseForm, IRefreshData
    {
        #region 作者
        /// <summary>
        /// 软件开发： 山西省肿瘤医院 药学部 王斌
        /// 电话：15234080782
        /// QQ:1150015857
        /// 
        /// </summary>
        #endregion

        #region 变量
        /// <summary>
        ///视图
        /// <summary>
        internal DataView　DvDept, DvOperators, DvWorkGroups, DvWorkGroupsForSend, DvWorkGroupsForSend_AddTempGroup;
        public DataView DvPatientFlow;
       internal IGetCmd igetCmd = null, igetCmd_DefaultReturnLast = null, igetCmd_DefaultReturnNext = null, igetCmd_CurrentReturn = null;
       internal GetCmd.CreateCmdClass ccc = null;
       internal Dictionary<string, string> dicReceive, dicSend;
       internal IExec iexec = new Exec();
       internal IFind ifind = new FindData();
       internal ICasePosition iPosition = new CasePosition();
        /// <summary>
        /// 数据库中不存在
        /// </summary>
       internal bool bDataBaseNotExists = true;
        /// <summary>
        /// 属查询出的数据，非扫描出的数据
        /// </summary>
       internal bool bDataIsFind_Receive = false, bDataIsFind_Send = false;
       internal string strValid = "";
       
        #endregion

        #region 属性

       /// <summary>
       /// 扫描的接收行数
       /// </summary>
       internal int Count_ScanReceive
       {
           get
           {
               return _Count_ScanReceive;
           }
           set
           {
               _Count_ScanReceive = value;
               // AddRow(_strBarCode);原扫描代码使用。现作废。
           }
       }
       private int _Count_ScanReceive = 0;


       /// <summary>
       /// 扫描的发送行数
       /// </summary>
       internal int Count_ScanSend
       {
           get
           {
               return _Count_ScanSend;
           }
           set
           {
               _Count_ScanSend = value;
               // AddRow(_strBarCode);原扫描代码使用。现作废。
           }
       }
       private int _Count_ScanSend = 0;

       /// <summary>
       /// 自动接收的扫描的接收行数
       /// </summary>
       internal int Count_AutoReceive
       {
           get
           {
               return _Count_AutoReceive;
           }
           set
           {
               _Count_AutoReceive = value;
               if (_Count_AutoReceive % 10 == 0)
               {
                   DgCaseReceive.Refresh();
                   ChangeBtnEnabled(false);
                   Thread.Sleep(2500);
                   AutoReceive();
                   ChangeBtnEnabled(true);
               }
           }
       }

  
       private int _Count_AutoReceive = 0;


       /// <summary>
       /// 自动接收的扫描的发送行数
       /// </summary>
       internal int Count_AutoSend
       {
           get
           {
               return _Count_AutoSend;
           }
           set
           {
               _Count_AutoSend = value;

               if (_Count_AutoSend % 10 == 0)
               {
                   DgCaseSend.Refresh();
                   ChangeBtnEnabled(false);
                   Thread.Sleep(2500);
                   AutoSend();
                   ChangeBtnEnabled(true);
                   
               }
           }
       }
       private int _Count_AutoSend = 0;

        /// <summary>
        /// 当前BarCode
        /// </summary>
        internal string StrBarCode
        {
            get
            {
                return _strBarCode;
            }
            set
            {
                _strBarCode = value;
               // AddRow(_strBarCode);原扫描代码使用。现作废。
            }
        }
        private string _strBarCode = "";

        /// <summary>
        /// 当前组Id
        /// </summary>
        internal int CurrentGroupId
        {
            get
            {
                return _currentGroupId;
            }
            set
            {
                _currentGroupId = value;
            }
        }
        private int _currentGroupId = -1;

        /// <summary>
        /// 下一步的组Id
        /// </summary>
        internal int DefaultNextGroupId
        {
            get
            {
                return _defaultnextGroupId;
            }
            set
            {
                _defaultnextGroupId = value;
            }
        }
        private int _defaultnextGroupId = -1;

        /// <summary>
        /// 默认的上一步的组Id
        /// </summary>
        internal int DefaultLastGroupId
        {
            get
            {
                return _defaultlastGroupId;
            }
            set
            {
                _defaultlastGroupId = value;
            }
        }
        private int _defaultlastGroupId = -1;

            /// <summary>
        /// 接收前是否检查上一步的组Id是否存在
        /// </summary>
        internal bool bCheckLastGroupId
        {
            get
            {
                return tSMI_CheckLastGroupId.Checked;
            }
            set
            {
                tSMI_CheckLastGroupId.Checked = value;
            }
        }
        

        /// <summary>
        /// 当前的上一步的组Id
        /// </summary>
        internal int CurrentLastGroupId
        {
            get
            {
                return _currentlastGroupId;
            }
            set
            {
                _currentlastGroupId = value;
            }
        }
        private int _currentlastGroupId = -1;

        /// <summary>
        /// 当前的下一步的组Id
        /// </summary>
        internal int CurrentNextGroupId
        {
            get
            {
                return _currentnextGroupId;
            }
            set
            {
                _currentnextGroupId = value;
            }
        }
        private int _currentnextGroupId = -1;

        /// <summary>
        /// 上一步的组Id是否能在新接收的行中找到？
        /// </summary>
        internal bool bExistsLastGroupId
        {
            get
            {
                return _bExistsLastGroupId;
            }
            set
            {
                _bExistsLastGroupId = value;
            }
        }
        private bool _bExistsLastGroupId = false;

        /// <summary>
        /// 上一步的组Id是否与默认的DefaultLastGroupId一致？
        /// </summary>
        internal bool bEqualsLastGroupId
        {
            get
            {
                return _bEqualsLastGroupId;
            }
            set
            {
                _bEqualsLastGroupId = value;
            }
        }
        private bool _bEqualsLastGroupId = false;

        /// <summary>
        /// 更新标志
        /// </summary>
        internal bool bUpdated
        {
            get
            {
                return _bupdated;
            }
            set
            {
                _bupdated = value;
            }
        }
        private bool _bupdated = false;
        
        /// <summary>
        /// 当前DataAdapter
        /// </summary>
        internal SqlDataAdapter DaReceive
        {
            get
            {
                return _Dacurrent;
            }
            set
            {
                _Dacurrent = value;
            }
        }
        private SqlDataAdapter _Dacurrent = null;

         /// <summary>
        /// 当前DataAdapter
        /// </summary>
        internal GridControlViewEx DgControlCurrent
        {
            get
            {
                return _Dgcurrent;
            }
            set
            {
                _Dgcurrent = value;
            }
        }
        private GridControlViewEx _Dgcurrent = null;

        #region Table
       
        /// <summary>
        /// 当前操作的表
        /// </summary>
        internal   string TableCurrent
        {
            get
            {
                return _tablecurrent;
            }
            set
            {
                _tablecurrent = value;

            }
        }
        private string _tablecurrent = "";
        
        /// <summary>
        /// 上一步操作的表
        /// </summary>
        internal  string TableLast
        {
            get
            {
                return _tablelast;
            }
            set
            {
                _tablelast = value;

            }
        }
        private string _tablelast = "";
       
        /// <summary>
        /// 下一步操作的表
        /// </summary>
        internal   string TableNext
        {
            get
            {
                return _tablenext;
            }
            set
            {
                _tablenext = value;

            }
        }
        private   string _tablenext = "";
 
        /// <summary>
        ///  默认的上一步操作的表
        /// </summary>
        internal string DefaultTableLast
        {
            get
            {
                return _defaulttablelast;
            }
            set
            {
                _defaulttablelast = value;

            }
        }
        private string _defaulttablelast = "";
 

        /// <summary>
        /// 默认的下一步操作的表
        /// </summary>
        internal string DefaultTableNext
        {
            get
            {
                return _defaulttablenext;
            }
            set
            {
                _defaulttablenext = value;

            }
        }
        private string _defaulttablenext = "";
        #endregion

        #region Return
        /// <summary>
        /// 是否正在双击回退
        /// </summary>
        internal bool bDoubleReturn
        {
            get
            {
                return _bdouble;
            }
            set
            {
                _bdouble = value;

            }
        }
        private bool _bdouble = false;
        #endregion

        #region 提示有差错的病案数
        /// <summary>
        /// 差错的病案数
        /// </summary>
        internal int CaseMistakeCount
        {
            get 
            { 
                return _mistakecount; 
            }
            set
            {
                _mistakecount = value;
            }
        }
        private int _mistakecount =0;

        /// <summary>
        /// 超过规定工作日的病案数
        /// </summary>
        internal int CaseOverDueCount
        {
            get
            {
                return _overduecount;
            }
            set
            {
                _overduecount = value;
            }
        }
        private int _overduecount = 0;
        #endregion
        #endregion

        #region 构造
        public CT_CaseDeliver()
        {
            InitializeComponent();
            Init();
            tabControlEx1.SelectedIndex = 1;//方便自动设置光标。
        }
        #endregion

        #region 事件
        #region 按钮事件
        #region 接收Tab页
        private void btnClose_Click(object sender, EventArgs e)
        {
            //if (bsCaseReceive.Count > 0)
            //    bsCaseReceive.Clear();
            //if (bSCaseSend.Count > 0)
            //    bSCaseSend.Clear();
            //if (bsSent.Count > 0)
            //    bsSent.Clear();
            this.Close();
        }

        private void btnRecieveBig_Click(object sender, EventArgs e)
        {
            AutoReceive();
        }

        private void AutoReceive()
        {
            if (DgCaseReceive.RowCount > 0)
            {
                if (igetCmd == null) return;
                ReceiveAction();

            }
            else
            {
                MessageBox.Show("没有可接收的数据！", "提示");
            }

            tbxReceiveBarCode.Focus();
        }
 
        private void btnRetrieval_Click(object sender, EventArgs e)
        {
            if (!bDataIsFind_Receive)
            {
                RetrievalAction();
                if (bDataIsFind_Receive)
                {
                    btnRetrieval.Text = "清 除(&C)";
                }
                tbxReceiveBarCode.Focus();
              
            }
            else
            {
                ClearDataForUI();
                InitDisplaylabel();
                if (!bDataIsFind_Receive)
                {
                    btnRetrieval.Text = "查　询(&F)";
                }
                tbxReceiveBarCode.Focus();
            }
        }

        private void Retrieval()
        {
            int iCount = 0;
            if (!TipStop(dsCaseManage.CollectCase, "bReceived",ref iCount)) return;
            
            if (DaReceive.SelectCommand.Parameters != null)
            {
                DaReceive.SelectCommand.Parameters.Clear();
            }
            if (igetCmd == null) return;
            DaReceive.SelectCommand.CommandText = igetCmd.GetSQLCmd_Receive();
            FindData(DaReceive, 1);
            DeleteCount_Auto(iCount);
            bDataIsFind_Receive = (dsCaseManage.CollectCase.Count > 0) ? true : false;
           
        }

        private bool TipStop(DataTable dt,string bColName,ref int icount)
        {
            object ovalue = DBNull.Value;
           // int icount = 0;
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                ovalue = dt.Rows[i][bColName];
                if (object.Equals(ovalue, true))
                    icount++;
            }
            if (bDataIsFind_Receive | bDataIsFind_Send) return true;
            if (icount > 0)
            {
                if (MessageBox.Show("查询将清除您已录入的数据，你确定要继续吗？", "提示", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) == System.Windows.Forms.DialogResult.Cancel) return　false;
            }
            return true;
        }

        private void btnClear_Click(object sender, EventArgs e)
        {
            ClearFocusedRowForUI();
        }

        private void btnReturn_Click(object sender, EventArgs e)
        {
           // ReturnCaseNotReceive();
         
        }
        private void btnUpToCirculate_Click(object sender, EventArgs e)
        {
            ExecUpToCirculateAction();
           
            tbxReceiveBarCode.Focus();
        }
 
      
        #endregion

        #region 发送Tab页
        private void btnSend_Click(object sender, EventArgs e)
        {
            AutoSend();
 
        }

        private void AutoSend()
        {
            try
            {
                if (DgCaseSend.RowCount > 0)
                {
                    if (igetCmd == null) return;

                    SendAction();

                }
                else
                {
                    MessageBox.Show("没有可发送的数据！", "提示");
                }

                tbxFind.Focus();

            }
            catch (InvalidOperationException ioe)
            {
                MessageBox.Show(ioe.Message, "错误");

                PException.Exception(ioe.Message, ioe);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "错误");

                PException.Exception(ex.Message, ex);
            }
        }
 
        private void btnSendFind_Click(object sender, EventArgs e)
        {
            SendFindForUI();
        }

        private void SendFindForUI()
        {
            cbxSendSelectAll.Checked = true;

            if (!bDataIsFind_Send)
            {
                SendFindAction();
                GetCaseMistakeCount();
                if (bDataIsFind_Send)
                {
                    btnSendFind.Text = "清 除(&C)";
                }
                tbxFind.Focus();
            }
            else
            {
                ClearDataForUI();
                if (!bDataIsFind_Send)
                {
                    btnSendFind.Text = "查　询（&F）";
                }
                tbxFind.Focus();
            }
        }
 
        private void btnSendClear_Click(object sender, EventArgs e)
        {
            ClearFocusedRowForUI();
        }

        private void btnSendClose_Click(object sender, EventArgs e)
        {
            btnClose_Click(sender, e);
        }
 
        private void btnSendReturn_Click(object sender, EventArgs e)
        {
            ReturnCase();
        }
 
        #endregion

        #endregion

        #region 窗体事件
        private void CT_CaseReceive_Load(object sender, EventArgs e)
        {
        
            //this.toolTipSimple1.SetToolTip(lbCurrentGroupName, "现在有几个信息提示");
            InitData();
            SetCurrentControl(DgCaseReceive);
        }
        private void CT_CaseReceiveA_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (CheckDataSaveState())
            {
                if (MessageBox.Show("信息尚未保存,关闭窗口信息将丢失,需要保存吗?", "警告", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button1) == System.Windows.Forms.DialogResult.Yes)
                {
                    e.Cancel = !SaveData();
                }
            }
        }

        private bool SaveData()
        {
            if (tabControlEx1.SelectedIndex == 0)
            {
                ReceiveActionA();
            }
            else
            {
                SendActionA();
            }
            return true;
        }

        private bool CheckDataSaveState()
        {
            bool bNotSave = false;
            DataTable dt = null;

            if (tabControlEx1.SelectedIndex == 0)
            {
                if (bsCaseReceive.Count > 0)
                {
                    bsCaseReceive.EndEdit();
                    dt = dsCaseManage.CollectCase.GetChanges();
                }
            }
            else
            {
                if (bSCaseSend.Count > 0)
                {
                    bSCaseSend.EndEdit();
                    dt = dsCaseManage.CheckScanCase.GetChanges();
                }

            }

            bNotSave = (dt != null) ? true : false;

            return bNotSave;
        }
        private void CT_CaseReceive_FormClosed(object sender, FormClosedEventArgs e)
        {
        }
        #endregion

        #region Binding事件
 
       

        internal void InsertNewRowForReceive(BindingSource bs)
        {
            try
            {

                DataView dv = (DataView)bs.List;

                if (CurrentGroupId != -1)
                {
                      int iCount = DvPatientFlow.Count;
                      if (iCount > 1)
                      {
                          bSRepeat.DataSource = DvPatientFlow;
                          this.panelRepeatCaseCode.Visible = true;
                          return;
                          //MessageBox.Show("有" + iCount.ToString() + "条数据，请注意选择！", "警告", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                      }
                      for (int i = 0; i < iCount; i++)
                      {
                          DsAll.DsCaseManage.CollectCaseRow newrowa = dsCaseManage.CollectCase.NewCollectCaseRow();
                          DataRow newrow = (DataRow)newrowa;
 

                              newrow["MedicalRecordNo"] = DvPatientFlow[i]["MedicalRecordNo"];
                              newrow["PatientName"] = DvPatientFlow[i]["PatientName"];
                              newrow["PatientFlowId"] = DvPatientFlow[i]["PatientFlowId"];
                              newrow["DischargeDate"] = DvPatientFlow[i]["DischargeDate"];
                              newrow["HospitalTime"] = DvPatientFlow[i]["HospitalTime"];
                              newrow["ReceiveId"] = DvPatientFlow[i]["ReceiveId"];

                              newrow["LastGroupId"] = DvPatientFlow[i]["LastGroupId"];
                              newrow["LastOperatorId"] = DvPatientFlow[i]["LastOperatorId"];
                              newrow["LastSendDate"] = DvPatientFlow[0]["LastSendDate"];

                              newrow["DepartmentId"] = DvPatientFlow[i]["DepartmentId"];
                              newrow["BarCode"] = DvPatientFlow[i]["BarCode"];
                              if(!DBNull.Value.Equals(DvPatientFlow[i]["BatchId"]))
                             // object s = DvPatientFlow[i]["BatchId"];
                              {
                                newrow["BatchId"] = DvPatientFlow[i]["BatchId"]; 
                              }
                          newrow["bReceived"] =  (iCount==1)? true:false;

                          dsCaseManage.CollectCase.Rows.InsertAt(newrow, i);
                          dsCaseManage.CollectCase.AcceptChanges();
                          dsCaseManage.CollectCase.Rows[i].SetModified();
 
                      }
                      bs.Position = 0;
                      Count_AutoReceive++;
                      tbxReceiveBarCode.Focus();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "AddNew ");
                PException.Exception(ex.Message, ex);
            }
        }

        internal void InsertNewRowForSend(BindingSource bs)
        {
            try
            {
                DataView dv = (DataView)bs.List;

                if (CurrentGroupId != -1)
                {
                    int iCount = DvPatientFlow.Count;
                    if (iCount > 1)
                    {
                        bSRepeat.DataSource = DvPatientFlow;
                        this.panelRepeatCaseCode_Send.Visible = true;

                        // dGRepeatCaseCodeInfo_Send.Focus();
                        return; //MessageBox.Show("有" + iCount.ToString() + "条数据，请注意选择！", "警告", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }
                    for (int i = 0; i < iCount; i++)
                    {
                        DsAll.DsCaseManage.CheckScanCaseRow newrowa = dsCaseManage.CheckScanCase.NewCheckScanCaseRow();
                        DataRow newrow = (DataRow)newrowa;


                        newrow["MedicalRecordNo"] = DvPatientFlow[i]["MedicalRecordNo"];
                        newrow["PatientName"] = DvPatientFlow[i]["PatientName"];
                        newrow["PatientFlowId"] = DvPatientFlow[i]["PatientFlowId"];
                        newrow["DischargeDate"] = DvPatientFlow[i]["DischargeDate"];
                        newrow["BarCode"] = DvPatientFlow[i]["BarCode"];
                        newrow["HospitalTime"] = DvPatientFlow[i]["HospitalTime"];
                        newrow["ReceiveId"] = DvPatientFlow[i]["ReceiveId"];
                        if (!DBNull.Value.Equals(DvPatientFlow[i]["BatchId"]))
                        // object s = DvPatientFlow[i]["BatchId"];
                        {
                            newrow["BatchId"] = DvPatientFlow[i]["BatchId"];
                        }
                        newrow["PatientFlowId"] = DvPatientFlow[i]["PatientFlowId"];
                        newrow["LastGroupId"] = DvPatientFlow[i]["LastGroupId"];
                        newrow["LastOperatorId"] = DvPatientFlow[i]["LastOperatorId"];
                        newrow["LastSendDate"] = DvPatientFlow[i]["LastSendDate"];

                        newrow["DepartmentId"] = DvPatientFlow[i]["DepartmentId"];
                        newrow["OperateGroupId"] = DvPatientFlow[i]["OperateGroupId"];
                        newrow["OperateDate"] = DvPatientFlow[i]["OperateDate"];
                        newrow["LReceiveId"] = DvPatientFlow[i]["LReceiveId"];


                        newrow["bSent"] = (iCount == 1) ? true : false;

                        dsCaseManage.CheckScanCase.Rows.InsertAt(newrow, i);
                        dsCaseManage.CheckScanCase.AcceptChanges();
                        dsCaseManage.CheckScanCase.Rows[i].SetModified();
 
                    }
                    bs.Position = 0;
                    Count_AutoSend++;
                    tbxFind.Focus();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "AddNew ");
                PException.Exception(ex.Message, ex);
            }
        }
 
        private void bsCaseReceive_PositionChanged(object sender, EventArgs e)
        {
             DisplayBigCurrentRow();
        }

        
        #endregion

        #region DataGrid
        private void DgSent_DoubleClick(object sender, EventArgs e)
        {
            if (DgSent.RowCount > 0)
            {
                string str = DgSent["PatientName_Sent", DgSent.CurrentCell.RowIndex].FormattedValue.ToString();
                if (MessageBox.Show("你确定要回退“" + str + "”的信息吗？", "提示", MessageBoxButtons.OKCancel, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) == System.Windows.Forms.DialogResult.Cancel) return;
                ReturnSentButNextGroupNotReceivedDataAction();
            }
        }

        private void DgCaseReceive_RowsAdded(object sender, DataGridViewRowsAddedEventArgs e)
        {
            DisplayBigCurrentRow();
        }

        private void DgCaseReceive_RowLeave(object sender, DataGridViewCellEventArgs e)
        {
            //InitDisplaylabel();
        }
        private void DgCaseSend_RowPostPaint(object sender, DataGridViewRowPostPaintEventArgs e)
        {
            SetRowBackColor(e);
        }
        private void DgCaseSend_CellPainting(object sender, DataGridViewCellPaintingEventArgs e)
        {
          
        }
        private void DgCaseReceive_SelectionChanged(object sender, EventArgs e)
        {
            DisplayBigCurrentRow();
        }
        #endregion

        #region 其它控件事件

        private void tabControlEx1_SelectedIndexChanged(object sender, EventArgs e)
        {
            showCaseMistakeCount();
            switch (tabControlEx1.SelectedIndex)
            {
                case 0:
                    tbxReceiveBarCode.Focus();
                    break;
                case 1:
                    tbxFind.Focus();
                    break;
            }
        }

        private void showCaseMistakeCount()
        {
            string strtip = "";
            if (CaseMistakeCount > 0)
            {
                strtip = "您组共有" + CaseMistakeCount.ToString() + "份病案有差错，";
            }
            if (CaseOverDueCount > 0)
            {
                if (strtip.Length > 0)
                {
                    strtip += "共有" + CaseOverDueCount.ToString() + "份病案已超过规定工作日，";
                }
                else
                {
                    strtip = "您组共有" + CaseOverDueCount.ToString() + "份病案已超过规定工作日，";
                }
            }
        
            if (strtip.Length > 0)
            {
                strtip += " 请在“发送”页面点“查询”查看详细情况！";
                this.toolTipEx1.Control_Current = this.tabControlEx1.SelectedIndex == 0 ? tbxReceiveBarCode : tbxFind;
                 int X = this.tabControlEx1.SelectedIndex == 0 ? tbxReceiveBarCode.Location.X : tbxFind.Location.X;
                int Y = this.tabControlEx1.SelectedIndex == 0 ? tbxReceiveBarCode.Location.Y : tbxFind.Location.Y;
                this.toolTipEx1.TipAfterSave(strtip, this.toolTipEx1.Control_Current,0, Y, 3000);
                 
            }
        }

        #region 编辑框事件
        private void tbxReceiveBarCode_KeyDown(object sender, KeyEventArgs e)
        {
            switch (e.KeyCode)
            {
                case Keys.Enter:
                    if (panelRepeatCaseCode.Visible)
                    {
                        AddRowToDataGridControl();
                    }
                    else
                    {
                        AddRow(tbxReceiveBarCode.Text.Trim());
                    }
                    break;
                case Keys.Up:
                    if (panelRepeatCaseCode.Visible)
                    {
                        UpSelectRow(bSRepeat);
                    }
                    else
                    {
                        UpSelectRow(bsCaseReceive);
                    }
                    break;
                case Keys.Down:
                    if (panelRepeatCaseCode.Visible)
                    {
                        DownSelectRow(bSRepeat);
                    }
                    else
                    {
                        DownSelectRow(bsCaseReceive);
                    }
                    break;
            }
        }

        private void tbxFind_KeyDown(object sender, KeyEventArgs e)
        {
            switch (e.KeyCode)
            {
                case Keys.Enter:
                    if (panelRepeatCaseCode_Send.Visible)
                    {
                        AddRowToDataGridControl();
                    }
                    else
                    {
                        AddRowToSend(tbxFind.Text.Trim());
                    }
                    break;
                case Keys.Up:
                    if (panelRepeatCaseCode_Send.Visible)
                    {
                        UpSelectRow(bSRepeat);
                    }
                    else
                    {
                        UpSelectRow(bSCaseSend);
                    }
                    break;
                case Keys.Down:
                    if (panelRepeatCaseCode_Send.Visible)
                    {
                        DownSelectRow(bSRepeat);
                    }
                    else
                    {
                        DownSelectRow(bSCaseSend);
                    }
                    break;
            }
        }


        private void tbxReceiveBarCode_MouseEnter(object sender, EventArgs e)
        {
           // tbxReceiveBarCode.Focus();
        }
        private void tbxFind_MouseEnter(object sender, EventArgs e)
        {
           // tbxFind.Focus();
        }

        #region 显示条编辑框事件
        private void tSTBxCaseNoFind_MouseEnter(object sender, EventArgs e)
        {
           // tSTBxSend.Focus();
        }
        private void tSTBxReceive_MouseEnter(object sender, EventArgs e)
        {
           // tSTBxReceive.Focus();
        }
        private void tSTBxCaseNoFind_TextChanged(object sender, EventArgs e)
        {
            try
            {
                bSCaseSend.Filter = " MedicalRecordNo like  '%" + tSTBxSend.Text + "%' or PatientNameSimple like  '%" + tSTBxSend.Text + "%'   or PatientName like  '%" + tSTBxSend.Text + "%'";
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "过滤");
            }

        }

        private void tSTBxReceive_TextChanged(object sender, EventArgs e)
        {
            try
            {
                bsCaseReceive.Filter = " MedicalRecordNo like  '%" + tSTBxReceive.Text + "%' or PatientNameSimple like  '%" + tSTBxReceive.Text + "%'   or PatientName like  '%" + tSTBxReceive.Text + "%'";
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "过滤");
            }
        }

        private void tSTBxSent_MouseEnter(object sender, EventArgs e)
        {
           // tSTBxSent.Focus();
        }

        private void tSTBxSent_TextChanged(object sender, EventArgs e)
        {
            try
            {
                bsSent.Filter = " MedicalRecordNo like  '%" + tSTBxSent.Text + "%' or PatientNameSimple like  '%" + tSTBxSent.Text + "%'   or PatientName like  '%" + tSTBxSent.Text + "%'";
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "过滤");
            }
        }


        private void tSTBxSend_KeyDown(object sender, KeyEventArgs e)
        {
            switch (e.KeyCode)
            {
                //case Keys.Escape: //不能使用。
                //    tSTBxSend.Text = "";
                //    break;
                case Keys.Up:
                    UpSelectRow(bSCaseSend);
                    break;
                case Keys.Down:
                    DownSelectRow(bSCaseSend);
                    break;
            }
        }


        private void tSTBxSent_KeyDown(object sender, KeyEventArgs e)
        {
            switch (e.KeyCode)
            {
                case Keys.Up:
                    UpSelectRow(bsSent);
                    break;
                case Keys.Down:
                    DownSelectRow(bsSent);
                    break;
            }
        }
        #endregion
        #endregion

        #region 过滤
        //private void tbxFind_TextChanged(object sender, EventArgs e)
        //{
        //   // bSCaseSend.Filter = "MedicalRecordNo like  '%" + tbxFind.Text + "%' or BarCode  like  '%" + tbxFind.Text + "%' or PatientName  like  '%" + tbxFind.Text + "%'";
        //}
       
        #endregion

        private void cbbxNextGroup_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (CT_Login.bRefreshing) return;
            if (cbbxNextGroup.SelectedIndex == -1) return;
            if (cbbxNextGroup.Text.Trim() == "") return;
            if (DefaultNextGroupId > 0)
            {
                if (!cbbxNextGroup.SelectedValue.Equals(DefaultNextGroupId))
                {
                    if (MessageBox.Show("您确定要发送到 “" + cbbxNextGroup.Text + "” 吗？", "警告", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) == System.Windows.Forms.DialogResult.Cancel)
                    {
                        cbbxNextGroup.SelectedValue = DefaultNextGroupId;
                    }
                }
            }
        }

        private void cbbxNextGroup_SelectedValueChanged(object sender, EventArgs e)
        {
           
        }

        private void cbbxNextGroup_SelectionChangeCommitted(object sender, EventArgs e)
        {

        }
        private void cbxAllSelect_CheckedChanged(object sender, EventArgs e)
        {
            AutoAllSelect(DgCaseReceive, cbxAllSelect.Checked);
        }

        private void cbxSendSelectAll_CheckedChanged(object sender, EventArgs e)
        {
            AutoAllSelect(DgCaseSend, cbxSendSelectAll.Checked);
            
        }
 
        private void AutoAllSelect(GridControlViewEx DgControl, bool bChecked)
        {
            switch (DgControl.Name)
            {
                case "DgCaseReceive":
                    for (int i = 0; i < DgControl.RowCount; i++)
                    {
                        if (bChecked)
                        {
                            DgControl.Rows[i].Cells["bReceived"].Value = bChecked;
                        }
                        else
                        {
                            DgControl.Rows[i].Cells["bReceived"].Value = DBNull.Value;
                        }
                        bsCaseReceive.Position = i;
                    }
                    if (bsCaseReceive.Count > 0)
                    {
                        bsCaseReceive.Position = 0;
                    }
                    break;
                case "DgCaseSend":
                     for (int i = 0; i < DgControl.RowCount; i++)
                    {
                        if (bChecked)
                        {
                            DgControl.Rows[i].Cells["bSent"].Value = bChecked;
                        }
                        else
                        {
                            DgControl.Rows[i].Cells["bSent"].Value  = DBNull.Value;
                        }
                        bSCaseSend.Position = i;
                    }
                     if (bSCaseSend.Count > 0)
                    {
                        bSCaseSend.Position = 0;
                    }
                    break;
            }

        }

        #endregion

        #region 右键菜单

        #region 已接收窗口
        private void tSMI_FindReceived_Click(object sender, EventArgs e)
        {
            DaReceive.SelectCommand.Parameters.Clear();
            DaReceive.SelectCommand.CommandText = igetCmd.GetSQLCmd_ReceiveFind();//"CTRECEIVEFindCollectdCase";
            DaReceive.SelectCommand.Parameters.Add("@OperatorId", SqlDbType.Int);
            DaReceive.SelectCommand.Parameters["@OperatorId"].Value = CT_Login.OperatorId;
            FindData(DaReceive,2);
            tbxReceiveBarCode.Focus();
        }

        private void tSMI_Clear_Click(object sender, EventArgs e)
        {
            ClearData(dsCaseManage.CollectCase_Received);
            tbxReceiveBarCode.Focus();
        }

        private void 本组已接收信息ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (this.splitContainerAll.Panel2Collapsed)
            {
                this.splitContainerAll.Panel2Collapsed = false;
                显示已接收面板ToolStripMenuItem.Text = "隐藏已接收面板";
            }
            DaReceive.SelectCommand.Parameters.Clear();
            DaReceive.SelectCommand.CommandText = igetCmd.GetSQLCmd_ReceiveFind_Group();// "CTRECEIVEFindCollectdCase_Group";
            DaReceive.SelectCommand.Parameters.Add("@OperateGroupId", SqlDbType.Int);
            DaReceive.SelectCommand.Parameters["@OperateGroupId"].Value = CT_Login.CurrentGroupId;
            FindData(DaReceive, 2);
            tbxReceiveBarCode.Focus();
        }

        private void 显示已接收面板ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (this.splitContainerAll.Panel2Collapsed)
            {
                this.splitContainerAll.Panel2Collapsed = false;
                显示已接收面板ToolStripMenuItem.Text = "隐藏已接收面板";
            }
            else
            {
                this.splitContainerAll.Panel2Collapsed = true;
                显示已接收面板ToolStripMenuItem.Text = "显示已接收面板";
            }
        }

        private void tSMI_CheckLastGroupId_Click(object sender, EventArgs e)
        {
            bCheckLastGroupId = tSMI_CheckLastGroupId.Checked;
        }

        #region 删除仅回收可用
        private void TSMI_DeleteErr_Click(object sender, EventArgs e)
        {
            DeleteCollectErr();
        }

        internal virtual void DeleteCollectErr()
        {

        }
        private void cMnuSFindReceived_Opening(object sender, CancelEventArgs e)
        {
            bool bEnabled =(bsCaseReceive.Current != null);
            cMnuSFindReceived.Enabled = bEnabled;
            if (!bEnabled) return;
            TSMI_DeleteErr.Enabled = (CT_Login.CurrentGroupId == 1 && bsCaseReceive.Current != null);
        }
        #endregion
        #endregion

        #region 已发送
        private void tSMI_Sent_Click(object sender, EventArgs e)
        {
            DaSent.SelectCommand.Parameters.Clear();
            DaSent.SelectCommand.CommandText = igetCmd.GetSQLCmd_SentFind();//"CTSENDFindCollectdCase";
            DaSent.SelectCommand.Parameters.Add("@OperatorId", SqlDbType.Int);
            DaSent.SelectCommand.Parameters["@OperatorId"].Value = CT_Login.OperatorId;
            FindData(DaSent, 5);
        }

        private void tSMI_SentClear_Click(object sender, EventArgs e)
        {
            ClearData(dsCaseManage.BindingCase);
            tbxFind.Focus();
        }

        private void 本组已发送信息ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            DaSent.SelectCommand.Parameters.Clear();
            DaSent.SelectCommand.CommandText = igetCmd.GetSQLCmd_SentFind_Group();// "CTSENDFindCollectdCase_Group";
            DaSent.SelectCommand.Parameters.Add("@OperateGroupId", SqlDbType.Int);
            DaSent.SelectCommand.Parameters["@OperateGroupId"].Value = CT_Login.CurrentGroupId;
            FindData(DaSent, 5);
        }

        private void 下一组未接收信息ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            SentFind_NextGroupNotReceive();
        }

        private void SentFind_NextGroupNotReceive()
        {
            DaSent.SelectCommand.Parameters.Clear();
            DaSent.SelectCommand.CommandText = igetCmd.GetSQLCmd_SentFind_NextGroupNotReceive();// "CTSENDFindCollectdCase_Group";
            DaSent.SelectCommand.Parameters.Add("@TableName", SqlDbType.NVarChar, 20);
            DaSent.SelectCommand.Parameters["@TableName"].Value = CT_Login.TableCurrent;
            DaSent.SelectCommand.Parameters.Add("@OperatorId", SqlDbType.Int);
            DaSent.SelectCommand.Parameters["@OperatorId"].Value = CT_Login.OperatorId;
         
            FindData(DaSent, 5);
        }
        #endregion

        #region 其它
        private void tSMI_SelectDefaultGroup_Click(object sender, EventArgs e)
        {
            SetDefaultGroup();
        }

        private void SetDefaultGroup()
        {
            if (DefaultNextGroupId > 0)
            {
                this.Invoke((MethodInvoker)delegate
                {
                    cbbxNextGroup.SelectedValue = DefaultNextGroupId;
                });
            }
        }

        #endregion
 
        #endregion

        #endregion

        #region 方法
        #region Init
        private void SetCurrentControl(GridControlViewEx DgControl)
        {
            DgControlCurrent = DgControl;
            tabControlEx1.SelectedIndex = 0;
            tbxReceiveBarCode.Focus();
        }

        internal void Init()
        {
            if (!initCmd())
            {
                this.Close();
                return;
            }

            InitCon();

            int tempX = btnClear.Location.X;
            int tempY = btnClear.Location.Y;
            int tempWidth = btnClear.Width;
 
            if (CT_Login.CurrentGroupId == 5)//库房管理组
            {
                groupBox1.Width = 667;
                btnClose.Location = new Point(tempX + 2 * tempWidth, tempY);//依分辨率变化
                btnUpToCirculate.Location = new Point(tempX + tempWidth, tempY);
                btnUpToCirculate.Visible = true;
                gBxCurrentGroup.Location = new Point(693, 6);
            }
            else
            {
                groupBox1.Width = 570;
                btnClose.Location = new Point(tempX + tempWidth, tempY);
                btnUpToCirculate.Location = new Point(tempX + 2 * tempWidth, tempY);
                btnUpToCirculate.Visible = false;
                gBxCurrentGroup.Location = new Point(600, 6);
            }

            //病案回收组不回退。
            btnSendReturn.Enabled = (CT_Login.CurrentGroupId == 1) ? false : true;

            if (SystemInformation.PrimaryMonitorSize.Height <=1024)
            {
                panelRight.Visible = false;
            }
            else
            {
                panelRight.Visible = true;
            }
        }

        internal void InitCon()
        {
            DaReceive = DaCollectCase;
            CT_Login.SetCon(DaReceive);
            CT_Login.SetCon(DaSend);
            CT_Login.SetConOnlySelect(DaSent);
        }

        internal bool initCmd()
        {
 //#if !DEBUG
　　　　　　　 ccc = new GetCmd.CreateCmdClass();
            igetCmd = ccc.GetISQLCmd(CT_Login.TableCurrent);
            igetCmd_DefaultReturnLast = ccc.GetISQLCmd(CT_Login.DefaultTableLast);
            igetCmd_DefaultReturnNext = ccc.GetISQLCmd(CT_Login.DefaultTableNext);

 
                if (igetCmd == null)
                {
                    string strtip = "命令初始化失败！系统无法使用！请联系 系统管理员！(可能因能所在的组“不必使用该功能”引起！)";
                    MessageBox.Show(strtip);
                    PException.Exception(strtip);
                    this.Close();
                    return false;
                }
       

                dicReceive = igetCmd.getCmd_ReceiveSaveData();
                dicSend = igetCmd.getCmd_SendSaveData();
           
            if (!GetCmdFromDic(DaCollectCase, dicReceive)) return false;
            if (!GetCmdFromDic(DaSend, dicSend)) return false;
 //#endif
            return true;
        }

        private bool GetCmdFromDic(SqlDataAdapter Da, Dictionary<string, string> dic)
        {
            try
            {
                if (dic == null) return false;
                Da.SelectCommand.CommandText = dic["Select"];
                if (dic["Insert"] != null | dic["Insert"] != "")
                    Da.InsertCommand.CommandText = dic["Insert"];
                if (dic["Update"] != null | dic["Update"] != "")
                    Da.UpdateCommand.CommandText = dic["Update"];
                if (dic["Delete"] != null | dic["Delete"] != "")
                    Da.DeleteCommand.CommandText = dic["Delete"];
                return true;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "getCmd");
                PException.Exception(ex.Message, ex);
                return false;
            }
        }

        private void InitData()
        {
            try
            {
                CurrentGroupId = CT_Login.CurrentGroupId;
 //#if !DEBUG
                    if (CurrentGroupId == -1)
                    {
                        MessageBox.Show("您所在的组没有指定，无法进行业务操作！", "警告", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        this.Close();
                    }
// #endif
                if (dsCaseManage.CollectCase.Count > 0)
                    dsCaseManage.CollectCase.Clear();

                if (dsCaseManage.CollectCase_Received.Count > 0)
                    dsCaseManage.CollectCase_Received.Clear();

                if (dsCaseManage.CheckScanCase.Count > 0)
                    dsCaseManage.CheckScanCase.Clear();

                if (dsCaseManage.BindingCase.Count > 0)
                    dsCaseManage.BindingCase.Clear();

                DvOperators =  new DataView( CT_Login.DvOperatorNames.Table);
                DvWorkGroups = new DataView( CT_Login.DvWorkGroups.Table);
                DvWorkGroupsForSend = CT_Login.DvWorkGroups_Send;
                DvWorkGroupsForSend_AddTempGroup = CT_Login.DvWorkGroups_Send_AddTempGroup;
                DvDept = new DataView(CT_Login.DvDepartment.Table);

                bsOperators.DataSource = DvOperators;
                bsworkGroups.DataSource = DvWorkGroups;
                bSDept.DataSource = DvDept;

                //if (CurrentGroupId == CT_Login.InsertedTempGroupId)
                //{
                //    cbbxNextGroup.DataSource = DvWorkGroupsForSend_AddTempGroup;
                //}
                //else
                {
                    cbbxNextGroup.DataSource = DvWorkGroupsForSend;
                }
                cbbxNextGroup.DisplayMember = "WorkGroupName";
                cbbxNextGroup.ValueMember = "WorkGroupId";
 
                DefaultLastGroupId = CT_Login.DefaultLastGroupId;

                DefaultNextGroupId = CT_Login.DefaultNextGroupId;

                if (DefaultNextGroupId != -1)
                {
                    cbbxNextGroup.SelectedValue = DefaultNextGroupId;
                }
                
                TableCurrent = CT_Login.TableCurrent;
                DefaultTableLast = CT_Login.DefaultTableLast;
                DefaultTableNext = CT_Login.DefaultTableNext;
                
                InitDisplaylabel(); 
                lbCurrentGroupName.Text = CT_Login.CurrentGroupName;
                lbCurrentGroupName_Send.Text = lbCurrentGroupName.Text;
                tbxReceiveBarCode.Text = "";
                tbxFind.Text = "";
                //cbxAllSelect.Checked = false;
                //cbxSendSelectAll.Checked = false;
                //cbxList.Checked = false;

                //cbbxNextGroup.Enabled = !CT_Login.bSendOtherAll;
                //btnSend.Enabled = !CT_Login.bSendOtherAll;

                if (CT_Login.CurrentGroupOrderId == 1)
                {
                    tSMI_CheckLastGroupId.Checked = false;
                }

                if (CT_Login.CurrentGroupId == 5 & CT_Login.bDefaultFlow)
                {
                    cbbxNextGroup.Enabled = btnSend.Enabled = false;
                    cbbxNextGroup.SelectedIndex = -1;
                }
                
                bool bUseCaseNo = (CT_Login.ScanType_Current == CT_Login.ScanType.ScanMedicalRecordNo) ? true : false;
                lbBarCode.Text = lbStrBarCode.Text = bUseCaseNo ? "病案号" : "条形码";

                GetCaseMistakeCount();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "InitData");
                PException.Exception(ex.Message, ex);
            }
        }
 
        private void AddTrans(SqlDataAdapter DaName, SqlTransaction update)
        {
            DaName.SelectCommand.Transaction = update;
            DaName.InsertCommand.Transaction = update;
            DaName.UpdateCommand.Transaction = update;
            DaName.DeleteCommand.Transaction = update;
        }

        private void InitDisplaylabel()
        {
            InitLabel(); 
        }

        private void InitLabel()
        {
            lbMedicalRecordNo2.Text = "";
            lbPatientName2.Text = "";
            lbDischargeDate2.Text = "";
            lbBarCode2.Text = "";
            lbLastSendDate2.Text = "";
            lbLastOperator2.Text = "";
            lbLastGroup2.Text = "";
        }
        #endregion

        #region AddData
        private void AddRow(string _strBarCode)
        {
            if (_strBarCode.Trim() == "")
            {
                MessageBox.Show("没有条形码信息！");
                return;
            }
            if (TipNotOperate()) return;
            InitIndicate();
            InitDisplaylabel();

            CheckAndGetDataByCode(_strBarCode);
        }

        internal virtual void CheckAndGetDataByCode(string _strBarCode)
        {
            if (!CheckDataGrid(_strBarCode)) return;
            GetDataByBarCode(_strBarCode);
            ClearBarCode();
        }

        internal void ClearBarCode()
        {
            tbxReceiveBarCode.Text = "";
            tbxFind.Text = "";
        }

        private void AddRowToSend(string _strBarCode)
        {
            if (_strBarCode.Trim() == "")
            {
                MessageBox.Show("没有条形码信息！");
                return;
            }
            if(TipNotOperate()) return;
            InitIndicate();
            InitDisplaylabel();

            if (!CheckDataGrid(_strBarCode)) return;
            GetDataByBarCode(_strBarCode);
            
            tbxFind.Text = "";
            
        }

        private bool TipNotOperate()
        {
            bool bEnableOperate = false;
            string tip = "";
            bEnableOperate = (tabControlEx1.SelectedIndex == 0)? (bDataIsFind_Receive && bsCaseReceive.Count > 0):(bDataIsFind_Send && bSCaseSend.Count > 0);
            tip = (tabControlEx1.SelectedIndex == 0) ? "不能接收" : "不能发送";
            if(bEnableOperate) 
            {
                MessageBox.Show("查询出的数据，" + tip + "！,请先清除！", "提示");
            }
            return bEnableOperate;
        }

        /// <summary>
        /// Init标志项
        /// </summary>
        private void InitIndicate()
        {
            bDataBaseNotExists = true;
        }
 
        internal virtual bool CheckDataGrid(string strBarCode)
        {
            bool bBarCode = (CT_Login.ScanType_Current == CT_Login.ScanType.ScanBarCode)? true:false;
            string strCol = "";
            if (tabControlEx1.SelectedIndex == 0)
            {
                strCol = (bBarCode) ? "barCodeCol" : "MedicalRecordNo";
                return CheckDataGrid(DgCaseReceive, strCol, strBarCode);
            }
            else
            {
                strCol = (bBarCode) ? "BarCodeCol_Send" : "MedicalRecordNo_Send";
                return CheckDataGrid(DgCaseSend, strCol, strBarCode);
            }
        }

        private bool CheckDataGrid(GridControlViewEx Dg,string strColName , string strBarCode)
        { 
            bool bNotExists =true;
            int index = -1;
            for (int i = 0; i < Dg.RowCount; i++)
            {
                if (Dg[strColName, i].Value.Equals(strBarCode))
                {
                    index = i;
                    bNotExists = false;
                    break;
                }
            }
            if (!bNotExists)
            {
                MessageBox.Show("您已扫录，系统将自动给您定位到该行！","提示");
                 Dg.SelectedRows[0].Selected = false;
                
                Dg.Rows[index].Selected = true;
                Dg.FirstDisplayedScrollingRowIndex = index;
 
                ClearBarCode();
            }
            return bNotExists;
        }
 

        private void DisplayBigCurrentRow()
        {
            try
            {
                if (bsCaseReceive.Count <= 0) return;
                var iindex = bsCaseReceive.Position;

                if (DgCaseReceive.RowCount <= 0)
                {
                    InitDisplaylabel();
                    if (iindex > -1)
                    {
                        //MessageBox.Show("有数据，但未显示！","错误");
                    }
                    return;
                }
                else if (DgCaseReceive.RowCount == 1)
                {
                    iindex = 0;
                }
                if (iindex < 0) return;
 
                    if (DgCaseReceive["MedicalRecordNo", iindex].Value != null)
                    {
                        lbMedicalRecordNo2.Text = DgCaseReceive["MedicalRecordNo", iindex].Value.ToString();
                    }
                    if (DgCaseReceive["PatientName", iindex].Value != null)
                    {
                        lbPatientName2.Text = DgCaseReceive["PatientName", iindex].Value.ToString();
                    }
                    if (DgCaseReceive["DischargeDate", iindex].Value != null)
                    {
                        lbDischargeDate2.Text =  string.Format("{0:yyyy-MM-dd}", DgCaseReceive["DischargeDate", iindex].Value);
                    }
                    if (DgCaseReceive["barCodeCol", iindex].Value != null)
                    {
                        lbBarCode2.Text  = DgCaseReceive["barCodeCol", iindex].Value.ToString();
                    }
                    var vlastgroupid = DgCaseReceive["LastGroupId", iindex].Value;
                    if (!DBNull.Value.Equals(vlastgroupid) & vlastgroupid != null)
                    {
                        if (CT_Login.DicGroupIdNames.Count <= 0) return;
                        var iv = int.Parse(vlastgroupid.ToString());
                        lbLastGroup2.Text = CT_Login.DicGroupIdNames[iv];
                    }
                    var vdate = DgCaseReceive["LastSendDate", iindex].Value;
                    if (!DBNull.Value.Equals(vdate) & vdate != null)
                    {
                        lbLastSendDate2.Text =  string.Format("{0:dd号HH点mm分}", vdate);
                    }
                    var vlastOperatorid = DgCaseReceive["LastOperatorId", iindex].Value;
                    if (!DBNull.Value.Equals(vlastOperatorid) & vlastOperatorid != null)
                    {
                        if (CT_Login.DicOperatorIdNames.Count <= 0) return;
                        var iv = int.Parse(vlastOperatorid.ToString());
                        lbLastOperator2.Text =  CT_Login.DicOperatorIdNames[iv];
                    }
               
            }
            catch (ArgumentOutOfRangeException aoe)
            {
                MessageBox.Show(aoe.Message, "显示错误");
                PException.Exception(aoe.Message, aoe);
            }
            catch (InvalidOperationException ioe)
            {
                MessageBox.Show(ioe.Message, "显示错误");
                PException.Exception(ioe.Message, ioe);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "显示错误");
                PException.Exception(ex.Message, ex);
            }
        }

        internal virtual void GetDataByCodeBase(string strCmd, string strCode)
        {
        }

       
        internal virtual  void GetDataByBarCode(string strBarCode)
        {

            if (tabControlEx1.SelectedIndex == 0)
            {
                GetDataByBarCodeBaseForReceive(igetCmd.GetSQLCmd_ReceiveDataByBarCode(), strBarCode);
            }
            else
            {
                GetDataByBarCodeBaseForSend(igetCmd.GetSQLCmd_SendDataByBarCode(), strBarCode);
            }
            
        }

       

        internal virtual void GetDataByBarCodeBaseForReceive(string strCmd,string strBarCode)
        {
            try
            {
                if (strCmd.Trim() == "")
                {
                    MessageBox.Show("Cmd未设置！","警告");
                    return;
                }
 
                DvPatientFlow = CSQL.GetInfoModel(strCmd, "BarCode", strBarCode, CT_Login.SqlDbCon);

                if (DvPatientFlow.Count >= 1)
                {
                    AddDataToRowForReceive();
                }
                else if (DvPatientFlow.Count < 1)
                {
                    string strPosition = iPosition.CheckCasePositon(strBarCode,CT_Login.ScanType_Current);
                 MessageBox.Show(strPosition, "提示2");
                    ClearBarCode();
                }                
            }
            catch (SqlException sec)
            {
                MessageBox.Show(sec.Message, "提示");
                PException.Exception(sec.Message, sec);
            }
            catch (Exception ec)
            {
                MessageBox.Show(ec.Message, "提示");
                PException.Exception(ec.Message, ec);
            }
        }

        private void GetDataByBarCodeBaseForSend(string strCmd, string strBarCode)
        {
            try
            {
                if (strCmd.Trim() == "")
                {
                    MessageBox.Show("Cmd未设置！", "警告");
                    return;
                }
                Dictionary<string, object> dic = new Dictionary<string, object>();
                dic.Add("BarCode", strBarCode);
                dic.Add("OperatorId", CT_Login.OperatorId);
                
                DvPatientFlow = CSQL.GetInfoModel(strCmd, dic, CT_Login.SqlDbCon);

                if (DvPatientFlow.Count >= 1)
                {
                    AddDataToRowForSend();
                }
                else if (DvPatientFlow.Count < 1)
                {
                    string strPosition = iPosition.CheckCasePositon(strBarCode, CT_Login.ScanType_Current);
                    MessageBox.Show(strPosition, "提示2");
                    ClearBarCode();
                }
            }
            catch (SqlException sec)
            {
                MessageBox.Show(sec.Message, "提示");
                PException.Exception(sec.Message, sec);
            }
            catch (Exception ec)
            {
                MessageBox.Show(ec.Message, "提示");
                PException.Exception(ec.Message, ec);
            }
        }
 
        
        private void AddDataToRowForReceive()
        {
            bsCaseReceive.EndEdit();
            InsertNewRowForReceive(bsCaseReceive);
         
        }

        private void AddDataToRowForSend()
        {
            bSCaseSend.EndEdit();
            InsertNewRowForSend(bSCaseSend);
           
        }
        #endregion

        #region SaveData

        #region Update
        private bool UpdateData(BindingSource bs, GridControlViewEx gv, SqlDataAdapter da, DataTable dt)
        {
            try
            {
                bUpdated = false;
                 bs.EndEdit();
                DataTable dttemp = null;
                if (bs.Current != null)
                {
                    //gv.EndEdit();
                    dttemp = dt.GetChanges();
                    if (dttemp != null)
                    {
                        da.Update(dttemp);
                        dt.AcceptChanges();
                        bUpdated = true;
                    }
                    else
                    {
                        MessageBox.Show("没有可保存的信息，保存失败！", "提示");
                        return false;
                    }
                }

                return true;
            }
            catch (System.Data.ConstraintException ce)
            {
                MessageBox.Show(ce.Message, "更新数据");
                PException.Exception(ce.Message, ce);
                return false;
            }
            catch (System.Data.DBConcurrencyException ex)
            {
                createMessage(ex);
                PException.Exception(ex.Message, ex);
                return false;
            }
            catch (SqlException oex)
            {
                if (!AutoModifyErr(oex.Message))
                {
                    MessageBox.Show(oex.Message, "sql更新数据");
                    PException.Exception(oex.Message, oex);
                }
                return false;
            }
            catch (Exception ex)
            {
                if (!AutoModifyErr(ex.Message))
                {
                    MessageBox.Show(ex.Message, "更新数据");
                    PException.Exception(ex.Message, ex);
                }
                return false;
            }
        }

        internal virtual bool AutoModifyErr(string strErr)
        {
            return false;
        }
        #endregion
      
        #region Receive

        private bool ReceiveDataBig()
          {
              try
              {
                  DgCaseReceive.BeginEdit(true);
                  InitDeleteDic();
                  string strTip = "";
                  int icount = 0;
                  if (cbxAllSelect.Checked)
                  {
                      for (int i = 0; i < DgCaseReceive.RowCount; i++)
                      {
                          if (bool.Equals(DgCaseReceive.Rows[i].Cells["bReturned_Receive"].Value, true)) break;

                          if (bool.Equals(DgCaseReceive.Rows[i].Cells["bReceived"].Value, true))
                          {
                              if (bCheckLastGroupId)
                              {
                                  if (!CheckNullValueOfSendInfoWhenReceive(i, ref strTip)) break;
                              }
                              SetRowDataForReceive(i, true);
                              icount++;
                          }
                          else
                          {
                              RecordIdOrSetNull(i);
                          }
                      }
                      if (strTip != "")
                      {
                          MessageBox.Show(strTip, "接收错误");
                           PException.Exception(strTip);
                          return false;
                      }
                  }
                  else
                  {
                      int iCurrentIndex = DgCaseReceive.CurrentCell.RowIndex;
                      if (bool.Equals(DgCaseReceive.Rows[iCurrentIndex].Cells["bReturned_Receive"].Value, true))
                      {
                          strTip = "不能接收已回退的数据！";
                          goto Tip;
                      }
                      if (bool.Equals(DgCaseReceive.Rows[iCurrentIndex].Cells["bReceived"].Value, true))
                      {
                          if (bCheckLastGroupId)
                          {
                              CheckNullValueOfSendInfoWhenReceive(iCurrentIndex, ref strTip);
                          }
                          SetRowDataForReceive(iCurrentIndex, true);
                      }
                      else
                      {
                          RecordIdOrSetNull(iCurrentIndex);
                      }
                  }

                  DgCaseReceive.EndEdit();

                  if (cbxAllSelect.Checked)
                  {
                      if (icount == 0)
                      {
                          MessageBox.Show("您选择了“全选”，但没选择任何行，请选择！", "提示");
                          return false;
                      }
                  }

                  DeleteNoSelectedRows();
 
                  Tip:
                  if (strTip != "")
                  {
                      MessageBox.Show(strTip, "提示");
                      return false;
                  }
               
                      Count_ScanReceive += dsCaseManage.CollectCase.Count;
                      this.lbDisplayBigNumber.Text = Count_ScanReceive.ToString();
                  
                   if (!this.lbDisplayBigNumber.Visible)
                       this.lbDisplayBigNumber.Visible = true;

                  if (!UpdateData(bsCaseReceive, DgCaseReceive, DaReceive, dsCaseManage.CollectCase)) return false;
                  DaReceive.SelectCommand.Parameters.Clear();
                  DaReceive.SelectCommand.CommandText = igetCmd.GetSQLCmd_ReceiveFind();
                  DaReceive.SelectCommand.Parameters.Add("@OperatorId", SqlDbType.Int);
                  DaReceive.SelectCommand.Parameters["@OperatorId"].Value = CT_Login.OperatorId;

                  return true;
              }
              catch (ArgumentOutOfRangeException are)
              {
                  MessageBox.Show(are.Message, "错误");
                  PException.Exception(are.Message, are);
                  return false;
              }
              catch (Exception ex)
              {
                  MessageBox.Show(ex.Message, "错误");
                  PException.Exception(ex.Message, ex);
                  return false;
              }
          }

        #region Virtual函数
        internal virtual void InitDeleteDic()
        { 
        }

        internal virtual void DeleteNoSelectedRows()
        {     
        }

        internal virtual void RecordIdOrSetNull(int i)
        {
            DgCaseReceive.Rows[i].Cells["bReceived"].Value = DBNull.Value;
        }
        #endregion

        private void SetRowDataForReceive(int i,bool bSelected)
        {
            try
            {
                DgCaseReceive.Rows[i].Cells["bReceived"].Value = true;
                DgCaseReceive.Rows[i].Cells["operateGroupIdCol"].Value = CurrentGroupId;
                DgCaseReceive.Rows[i].Cells["OperateDate"].Value = DateTime.Now;
                DgCaseReceive.Rows[i].Cells["OperatorId"].Value = CT_Login.OperatorId;
 
                CheckLastGroupId(i);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message,"接收行设置错误");
                PException.Exception(ex.Message, ex);
            }
        }
          #endregion

        #region Check
         private bool CheckSendError(int i, ref string strTip)
         {
             if (!CheckNullValueOfSendInfoWhenSend(i, ref strTip)) return false;
             if (!CheckExistsSent(i, ref strTip)) return false;
             return true;
         }

         private bool CheckGroupId(GridControlViewEx Dg, int i, string strLastOrNextGroupColName,bool bNext, ref string strTip)
         {
             var vGroupid = Dg.Rows[i].Cells[strLastOrNextGroupColName].Value;
             if (vGroupid == null || DBNull.Value.Equals(vGroupid))
             {
                 if (!bNext)
                 {
                     bExistsLastGroupId = false;
                     strTip = "不存在上一组的信息！";
                 }
               
             }
             else
             {
                 if (bNext)
                 {
                     CurrentNextGroupId = int.Parse(vGroupid.ToString());
                 }
                 else
                 {
                     bExistsLastGroupId = true;
                     CurrentLastGroupId = int.Parse(vGroupid.ToString());
                 }
                 
             }
             return bExistsLastGroupId;
         }
         private bool CheckLastGroupId(GridControlViewEx Dg, int i, string strLastGroupColName, ref string strTip)
        {
            var vlastGroupid = Dg.Rows[i].Cells[strLastGroupColName].Value;
            if ( vlastGroupid ==null || DBNull.Value.Equals(vlastGroupid))
            {
                bExistsLastGroupId = false;
                strTip ="不存在上一组的信息！";
            }
            else
            {
                bExistsLastGroupId = true;
                CurrentLastGroupId = int.Parse(vlastGroupid.ToString());
            }
             return bExistsLastGroupId;
         }

        private bool CheckLastGroupId(int i)
        {
            object vlastGroupid = DgCaseReceive.Rows[i].Cells["LastGroupId"].Value;
            if (vlastGroupid == null || DBNull.Value.Equals(vlastGroupid))
            {
                bExistsLastGroupId = false;
            }
            else
            {
                bExistsLastGroupId = true;

                CurrentLastGroupId = int.Parse(vlastGroupid.ToString());

                if (DefaultLastGroupId > 0)
                {
                    if (DefaultLastGroupId.Equals(vlastGroupid))
                    {
                        bEqualsLastGroupId = true;
                    }
                }
                if (CurrentLastGroupId == CurrentGroupId)
                {
                    MessageBox.Show("当前组与上一组Id一致，不能继续，请查看是否未刷新！","警告");
                    bEqualsLastGroupId = false;
                }
            }
            return bEqualsLastGroupId;
        }

        private bool CheckNullValueOfSendInfoWhenReceive(int i, ref string strTip)
        {
            var vlastGroupid = DgCaseReceive.Rows[i].Cells["LastGroupId"].Value;
            if (vlastGroupid == null || DBNull.Value.Equals(vlastGroupid))
            {
                strTip = "没有发送组信息";
                return false;
            }

            var vlastDate = DgCaseReceive.Rows[i].Cells["LastSendDate"].Value;
            if (vlastDate == null || DBNull.Value.Equals(vlastDate))
            {
                strTip = "没有发送时间信息";
                return false;
            }
            var vOperatorid = DgCaseReceive.Rows[i].Cells["LastOperatorId"].Value;
            if (vOperatorid == null || DBNull.Value.Equals(vOperatorid))
            {
                strTip = "没有发送人员信息";
                return false;
            }
            if (vlastGroupid.Equals(CurrentGroupId))
            {
                strTip  = "上一组与当前组Id一致，请查看是否未刷新！";
                return false;
            }
            return true;
        }

        private bool CheckNullValueOfSendInfoWhenSend(int i, ref string strTip)
        {
            var vCurrentGroupid = DgCaseSend.Rows[i].Cells["OperateGroupId"].Value;
            if (vCurrentGroupid == null || DBNull.Value.Equals(vCurrentGroupid))
            {
                strTip = "没有您组的信息";
                return false;
            }

            var vcurrentDate = DgCaseSend.Rows[i].Cells["SendDate"].Value;
            if (vcurrentDate == null || DBNull.Value.Equals(vcurrentDate))
            {
                strTip = "没有您操作时间的信息";
                return false;
            }

            var vOperatorid = DgCaseSend.Rows[i].Cells["SendOperatorId"].Value;
            if (DBNull.Value.Equals(vOperatorid))
            {
                strTip = "没有您姓名的信息";
                return false;
            }

            var vLastGroupId = DgCaseSend.Rows[i].Cells["LastGroupId_Send"].Value;
            //if (vLastGroupId == null || DBNull.Value.Equals(vLastGroupId)) return false;
            if (CurrentNextGroupId.Equals(vLastGroupId))
            {
                strTip = "您选择了发给您的组，请您直接点“回退”按钮！";
                return false;
            }
            //var vReturn = DgCaseSend.Rows[i].Cells["bReturned_Send"].Value;

            //if (bool.Equals(vReturn, true))
            //{
            //    strTip = "不可以发送已回退的数据！";
            //    return false;
            //}
            return true;
        }
    
        /// <summary>
        ///  //检查是否已发过
        /// </summary>
        /// <param name="i"></param>
        /// <param name="tip"></param>
        /// <returns></returns>
        private bool CheckExistsSent(int i, ref string strTip)
        {
            var vPatientFlowId = DgCaseSend.Rows[i].Cells["PatientFlowId"].Value;
            var PatientName = DgCaseSend.Rows[i].Cells["PatientName_Send"].Value;
            var CaseNo = DgCaseSend.Rows[i].Cells["MedicalRecordNo_Send"].Value;
            if (vPatientFlowId == null) return false;
            if (DefaultNextGroupId > 0)
            {
                if (DefaultNextGroupId.Equals(CurrentNextGroupId)) return true;
                TableNext = CT_Login.GetTableNameByGroupId(CurrentNextGroupId);
                string[] paname = { "CurrentGroupId", "NextGroupId", "NextTable", "PatientFlowId" };

                object[] values = {CurrentGroupId, CurrentNextGroupId, TableNext, vPatientFlowId };
                int rowcout = 0;

                try
                {
                    CSQL.ExecModel_Return("SendBeforeCheckDataIsDeal_ZLYY", paname, values, out rowcout, CT_Login.SqlDbCon);//存储过程为山西省肿瘤医院专用
                    if (rowcout <= 0)
                    {
                        string str = CaseNo + " － " + PatientName + " 未走完流程！该条不能发送！";
                        MessageBox.Show(str, "错误");
                        
                        return false;
                    }
                    return true;
                }
                catch (SqlException ser)
                {
                    MessageBox.Show(ser.Message, "SQL错误");
                    PException.Exception(ser.Message, ser);
                    return false;
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "错误");
                    PException.Exception(ex.Message, ex);
                    return false;
                }

                {
                    //string[] strpams = { "PatientFlowId", "NextGroupId" };
                    //object[] ovalues = { vPatientFlowId, DefaultNextGroupId };
                    //int icount = -1;
                    //string strSQL = igetCmd.GetSQLCmd_CheckExistsSentById();
                    //if (strSQL != "")
                    //{
                    //    CSQL.ExecModel(strSQL, strpams, ovalues, out icount, CT_Login.SqlDbCon);
                    //    if (icount > 0)
                    //    {
                    //        strTip = "该患者已发送过了。";
                    //        return false;
                    //    }
                    //}
                }
            }
            return true;
        }
        #endregion

        #region Send
        private bool SendDataBig()
        {
            object oValue = null;
            
                oValue = cbbxNextGroup.SelectedValue;
            
            if (oValue ==null || oValue.Equals(DBNull.Value)|| oValue.Equals(-1))
            {
                MessageBox.Show("发往哪个组？请选择！", "提示");
                return false;
            }
            else
            {
                CurrentNextGroupId = int.Parse(oValue.ToString());
            }
            if (CurrentGroupId.Equals(oValue))
            {
                MessageBox.Show("您不能发给自己！请重新选择！", "提示");
                return false;
            }

            TableNext = CT_Login.GetTableNameByGroupId(oValue);
            if (TableNext == "")
            {
                string strtip ="没有得到NextTable名称,请通知系统管理员！";
                MessageBox.Show(strtip, "错误");
                PException.Exception(strtip);
                return false;
            }

            try
            {
                DgCaseSend.BeginEdit(true);
                string strTip = "";
                int icount = 0 ;
                bool bError = false;
                if (this.cbxSendSelectAll.Checked)
                {
                    for (int i = 0; i < DgCaseSend.RowCount; i++)
                    {
                      
                        if (bool.Equals(DgCaseSend.Rows[i].Cells["bSent"].Value, true))
                        {
                            SetRowDataForSend(i, true);
                            if (!CheckSendError(i, ref strTip))
                            {
                                bError = true;
                                break;
                            }
                          
                            icount++;
                        }
                        else
                        {
                            DgCaseSend.Rows[i].Cells["bSent"].Value = DBNull.Value;
                        }
                 
                    }
                    if (bError)
                    {
                        if (strTip.Trim() != "")
                        {
                            MessageBox.Show(strTip);
                        }
                        return false;
                    }
  
                }
                else
                {
                    int iCurrentIndex = DgCaseSend.CurrentCell.RowIndex;

                    SetRowDataForSend(iCurrentIndex, true);
                    
                    if (!CheckSendError(iCurrentIndex, ref strTip))
                    {
                        MessageBox.Show(strTip);
                        return false;
                    }
                   
                }
                if (strTip != "")
                {
                    MessageBox.Show(strTip, "发送错误");
                    PException.Exception(strTip);
                    return false;
                }
                if (this.cbxSendSelectAll.Checked)
                {
                    if (icount == 0)
                    {
                        MessageBox.Show("您选择了“全选”，但没选择任何行，请选择！", "提示");
                        return false;
                    }
                }
             
                 DgCaseSend.EndEdit();
 
                 Count_ScanSend += dsCaseManage.CheckScanCase.Count;
                  this.lbDisplayBigNumber_Send.Text = Count_ScanSend.ToString();
               
                 if (!this.lbDisplayBigNumber_Send.Visible)
                     this.lbDisplayBigNumber_Send.Visible = true;

                if (!UpdateData(bSCaseSend, DgCaseSend, DaSend, dsCaseManage.CheckScanCase)) return false;
                InitDaSentCmd();
 
             　 return true;
            }
            catch (ArgumentOutOfRangeException are)
            {
                MessageBox.Show(are.Message, "发送错误");
                PException.Exception(are.Message, are);
                return false;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "发送错误");
                PException.Exception(ex.Message, ex);
                return false;
            }
        }
         
        private void SetRowDataForSend(int i, bool bSelected)
        {
            try
            {
                DgCaseSend.BeginEdit(false);
                if (!DgCaseSend["bSent", i].Value.Equals(true))
                {
                    DgCaseSend.Rows[i].Cells["bSent"].Value = true;
                }
                if (DgCaseSend["bReturned_Send", i].Value.Equals(true))
                {
                    DgCaseSend.Rows[i].Cells["bReturned_Send"].Value = DBNull.Value;
                }
                DgCaseSend.Rows[i].Cells["NextGroupId"].Value = CurrentNextGroupId;//cbbxNextGroup.SelectedValue;
                DgCaseSend.Rows[i].Cells["SendDate"].Value = DateTime.Now;
                DgCaseSend.Rows[i].Cells["SendOperatorId"].Value = CT_Login.OperatorId;
                DgCaseSend.EndEdit();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message,"设置发送行错误");
                PException.Exception(ex.Message, ex);
            }
        }

        #endregion
        #endregion

        #region 接收按钮
        private void CheckAndUpdateDataToLastStep()
        {
            if (DgCaseReceive.RowCount <= 0) return;
            if (!bUpdated) return;
           
            if (bEqualsLastGroupId) return;

            if (CurrentGroupId > 0)
            {
                if (cbxAllSelect.Checked)
                {
                    for (int i = 0; i < DgCaseReceive.RowCount; i++)
                    {
                        if (bool.Equals(DgCaseReceive.Rows[i].Cells["bReceived"].Value, true))
                        {
                            CheckLastGroupId(i);
                            if (!bExistsLastGroupId) break;
                            if (bEqualsLastGroupId) break;
                            GetPatientFlowIdAndUpdateDataToLastStep(i);
                        }
                    }
                }
                else
                {
                    int icurrentIndex = DgCaseReceive.CurrentCell.RowIndex;
                    CheckLastGroupId(icurrentIndex);
                   if (!bExistsLastGroupId) return;
                   if (bEqualsLastGroupId) return;
                  
                    GetPatientFlowIdAndUpdateDataToLastStep(icurrentIndex);
                }
            }
            else
            {
                string str ="不存在当前组Id的信息";
                MessageBox.Show(str,"接收更新");
                PException.Exception(str);
            }
        }

        private void GetPatientFlowIdAndUpdateDataToLastStep(int i)
        {
            long lid = -1;

            TableLast = CT_Login.GetTableNameByGroupId(CurrentLastGroupId);
            long.TryParse(DgCaseReceive["PatientFlowId_CaseReceive", i].Value.ToString(), out lid);
            UpdateDataToLastStep(lid, CurrentLastGroupId);
        }

        private void UpdateDataToLastStep(long PatientFlowId, int iLastGroupId)
        {
            string[] paname = { "CurrentTable", "LastGroupId", "LastTable", "PatientFlowId" };

            object[] values = { TableCurrent, iLastGroupId, TableLast, PatientFlowId };
            int rowcout = 0;

            try
            {
                CSQL.ExecModel("UpdateDataToLastStepAfterReceive", paname, values, out rowcout, CT_Login.SqlDbCon);
                if (rowcout <= 0)
                {
                    string str ="接收后数据记录失败！";
                    MessageBox.Show(str,"错误");
                    PException.Exception(str);
                }
            }
            catch (SqlException ser)
            {
                MessageBox.Show(ser.Message, "SQL错误");
                PException.Exception(ser.Message, ser);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "错误");
                PException.Exception(ex.Message, ex);
            }

        }
        #endregion

        #region 发送按钮

        private void CheckAndSendDataToNextStep()
        {
            if (DgCaseSend.RowCount <= 0) return;
           // if (cbbxNextGroup.SelectedIndex == -1) return;

            if (CurrentNextGroupId == -1) return;
            if (!bUpdated) return;
           // if (CT_Login.bDefaultFlow) return;//使用意义不大,影响对“对内流通”的发送。
            if (CT_Login.bUseInsertTempGroup & CurrentGroupId == 7)
            {//只有这种情况不做下面的处理。
            }
            else
            {
                if (CurrentNextGroupId.Equals(DefaultNextGroupId)) return;
            }
            long lid = -1;
            if (this.cbxSendSelectAll.Checked)
            {
                for (int i = 0; i < DgCaseSend.RowCount; i++)
                {
                    if (bool.Equals(DgCaseSend.Rows[i].Cells["bSent"].Value, true))
                    {
                        long.TryParse(DgCaseSend["PatientFlowId", i].Value.ToString(), out lid);
                        InsertDataToNextStep(lid);
                    }
                }
            }
            else
            {
                int icurrentIndex = DgCaseSend.CurrentCell.RowIndex;
                var o = DgCaseSend["PatientFlowId", icurrentIndex].Value;
                lid = long.Parse(o.ToString());
                InsertDataToNextStep(lid);
            }

        }

        private void InsertDataToNextStep(long PatientFlowId)
        {
           
            string[] paname = { "CurrentTable", "CurrentGroupId", "NextGroupId", "NextTable", "PatientFlowId" };
            string nextTable = TableNext;
           
            object[] values = { TableCurrent, CurrentGroupId, CurrentNextGroupId, nextTable, PatientFlowId };
            int rowcout = 0;

            try
            {
                CSQL.ExecModel("InsertDataToNextStepAfterSent", paname, values, out rowcout, CT_Login.SqlDbCon);
                if (rowcout <= 0)
                {
                    string str ="发送后数据记录失败！";
                    MessageBox.Show(str, "错误");
                    PException.Exception(str);
                }
            }
            catch (SqlException ser)
            {
                MessageBox.Show(ser.Message, "SQL错误");
                PException.Exception(ser.Message, ser);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "错误");
                PException.Exception(ex.Message, ex);
            }
        }
        #endregion

        #region 发送查询按钮

        private void SendBeforeFindByOperator()
        {
            int iCount = 0;
            if (!TipStop(dsCaseManage.CheckScanCase, "bSent",ref iCount)) return;

            if (DaSend.SelectCommand.Parameters != null)
            {
                DaSend.SelectCommand.Parameters.Clear();
            }
            if (igetCmd == null) return;
            DaSend.SelectCommand.CommandText = igetCmd.GetSQLCmd_ReceiveFind();
            DaSend.SelectCommand.Parameters.Add("@OperatorId", SqlDbType.Int);
            DaSend.SelectCommand.Parameters["@OperatorId"].Value = CT_Login.OperatorId;
            FindData(DaSend, 4);
            DeleteCount_Auto(iCount);
            bDataIsFind_Send = (dsCaseManage.CheckScanCase.Count > 0) ? true : false;

        }

        private void SendBeforeFindByGroup()
        {
            int iCount =0;
            if (!TipStop(dsCaseManage.CheckScanCase, "bSent", ref iCount)) return;

            if (DaSend.SelectCommand.Parameters != null)
            {
                DaSend.SelectCommand.Parameters.Clear();
            }
            if (igetCmd == null) return;
            DaSend.SelectCommand.CommandText = igetCmd.GetSQLCmd_ReceiveFind_Group();
            DaSend.SelectCommand.Parameters.Add("@OperateGroupId", SqlDbType.Int);
            DaSend.SelectCommand.Parameters["@OperateGroupId"].Value = CT_Login.CurrentGroupId;
            FindData(DaSend, 4);
            DeleteCount_Auto(iCount);
            if (dsCaseManage.CheckScanCase.Count > 0)
            {
                bDataIsFind_Send = true;
            }
        }
        #endregion

        #region 回退按钮
        private bool CheckAndUpdateDataToReturn(GridControlViewEx Dg, string strReturnColName, string strLastOrNextGroupColName, string PatientFlowIdColName, string ReceiveIdColName, string LastReceiveIdColName,string LastOperatorIdColName,bool bSent)
        {
            try
            {
                string strTip = "";
                if (Dg.RowCount <= 0) return false;
                bool bReturn = true;
                int ireturn = 0;
                if (CurrentGroupId > 0)
                {
                    if (this.cbxSendSelectAll.Checked)
                    {
                        for (int i = 0; i < Dg.RowCount; i++)
                        {
                            if (bool.Equals(Dg.Rows[i].Cells[strReturnColName].Value, true))
                            {
                                if (!CheckGroupId(Dg, i, strLastOrNextGroupColName, bSent, ref strTip)) break;
                                if (!CheckRepeatReturn(Dg, i, strLastOrNextGroupColName,PatientFlowIdColName, bSent, ref strTip)) break;
                                GetPatientFlowIdAndUpdateDataToReturn(Dg, PatientFlowIdColName, ReceiveIdColName, LastReceiveIdColName,LastOperatorIdColName, i, bSent);
                                ireturn++;
                            }
                        }
                        if (ireturn == 0)
                        {
                            strTip += "您选择了“全选”，但没有选择任何回退行，请选择！";
                        }
                    }
                    else
                    {
                        int iIndex = Dg.CurrentCell.RowIndex;
                        CheckGroupId(Dg, iIndex, strLastOrNextGroupColName, bSent, ref strTip);
                        CheckRepeatReturn(Dg, iIndex, strLastOrNextGroupColName, PatientFlowIdColName, bSent, ref strTip);
                        if (strTip != "")
                            goto Tip;
                        GetPatientFlowIdAndUpdateDataToReturn(Dg, PatientFlowIdColName, ReceiveIdColName, LastReceiveIdColName, LastOperatorIdColName, iIndex, bSent);
                    }

                }
                else
                {
                    bReturn = false;
                    string str = "不存在当前组Id的信息";
                    MessageBox.Show(str, "回退失败");
                    PException.Exception(str);
                }

               Tip:
                if (strTip != "")
                {
                    bReturn = false;
                    MessageBox.Show(strTip, "回退失败");
                }
                return bReturn;
            }
            catch (ArgumentException ae)
            {
                MessageBox.Show(ae.Message, "回退失败");
                PException.Exception(ae.Message,ae);
                return false;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "回退失败");
                PException.Exception(ex.Message, ex);
                return false;
            }
        }

        private bool CheckRepeatReturn(GridControlViewEx Dg, int i, string strLastOrNextGroupColName,string PatientFlowIdColName, bool bSent, ref string strTip)
        {
            long lpfid = -1;
            long.TryParse(Dg[PatientFlowIdColName, i].Value.ToString(), out lpfid);
           // int.TryParse(Dg[strLastOrNextGroupColName, i].Value.ToString(), out igroupid);
            //if(CurrentGroupId >0)
            if (lpfid <= 0)
            {
                strTip = "没有取到患者流编号！";
                return false;
            }

            if (CheckReturnDataExists(lpfid, CurrentGroupId))
            {
                strTip = "已回退过该患者信息！";
                return false;
            }
            return true;
        }

        private bool CheckAndUpdateDataToReturnForDouble(GridControlViewEx Dg, string strReturnColName, string strLastOrNextGroupColName, string PatientFlowIdColName, string ReceiveIdColName, string LastReceiveIdColName, string LastOperatorIdColName, bool bSent)
        {
            try
            {
                string strTip = "";
                if (Dg.RowCount <= 0) return false;
                bool bReturn = true;
                if (CurrentGroupId > 0)
                {
                        int icurrentIndex = Dg.CurrentCell.RowIndex;
                        CheckGroupId(Dg, icurrentIndex, strLastOrNextGroupColName, bSent, ref strTip);
                     CheckRepeatReturn(Dg, icurrentIndex, strLastOrNextGroupColName,PatientFlowIdColName, bSent, ref strTip);
                        if (strTip != "")
                            goto Tip;
                        GetPatientFlowIdAndUpdateDataToReturn(Dg, PatientFlowIdColName, ReceiveIdColName, LastReceiveIdColName,LastOperatorIdColName, icurrentIndex, bSent);

                }
                else
                {
                    bReturn = false;
                    string str = "不存在当前组Id的信息";
                    MessageBox.Show(str, "回退更新");
                    PException.Exception(str);
                }
                Tip:
                if (strTip != "")
                {
                    bReturn = false;
                    MessageBox.Show(strTip, "回退更新");
                }
                return bReturn;
            }
            catch (ArgumentException ae)
            {
                MessageBox.Show(ae.Message, "回退更新");
                PException.Exception(ae.Message, ae);
                return false;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "回退更新");
                PException.Exception(ex.Message, ex);
                return false;
            }
        }

        private bool GetPatientFlowIdAndUpdateDataToReturn(GridControlViewEx Dg, string PatientFlowIdColName, string ReceiveIdColName, string LastReceiveIdColName,string LastOperatorIdColName, int i,bool bSent)
        {
            long lid = -1, lReceiveId = -1, lLastReceiveId = -1;
            int ilastOperatorId = -1,iNextOperatorId =-1;
            TableLast = CT_Login.GetTableNameByGroupId(CurrentLastGroupId);
            TableNext = CT_Login.GetTableNameByGroupId(CurrentNextGroupId);
            long.TryParse(Dg[PatientFlowIdColName, i].Value.ToString(), out lid);
            int.TryParse(Dg[LastOperatorIdColName, i].Value.ToString(), out ilastOperatorId);
            long.TryParse(Dg[ReceiveIdColName, i].Value.ToString(), out lReceiveId);
            long.TryParse(Dg[LastReceiveIdColName, i].Value.ToString(), out lLastReceiveId);

            if (bSent)
            {
                //此处列名不是变量
                int.TryParse(Dg["NextOperatorId", i].Value.ToString(), out iNextOperatorId);
                if (iNextOperatorId > 0)
                {
                    MessageBox.Show("此病案已被下一组操作员接收，您不能直接回退\n（若必须回退，请让对方点“回退”按钮）！", "回退失败", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return false;
                }
            }
            else
            {
                if (ilastOperatorId <= 0)
                {
                    MessageBox.Show("没有上一组操作员的信息！", "回退失败１");
                    return false;
                }

                if (lLastReceiveId <= 0)
                {
                    MessageBox.Show("没有上一组接收编号的信息！", "回退失败１");
                    return false;
                }
            }
           
            if (bSent)
            {
                if (!UpdateDataToReturnForSent(lid, CurrentGroupId, lReceiveId)) return false;
            }
            else
            {
                if (!UpdateDataToReturnForNotSend(lReceiveId, lLastReceiveId)) return false;
            }
 
             return true;
        }
 
       /// <summary>
        /// 退未发的：对上一表更新而且插入新行,当前表只更新;
       /// </summary>
       /// <param name="lreceiveId"></param>
       /// <param name="LastReceiveId"></param>
       /// <returns></returns>
        private bool UpdateDataToReturnForNotSend( long lreceiveId, long LastReceiveId)
        {
            string strCmd = ""; string strCmdLast = "";
            string[] paname = { "OperatorId", "ReceiveId" };

            object[] values = { CT_Login.OperatorId, lreceiveId };

            string[] panameForLast = { "OperatorId", "ReceiveId" };

            object[] valuesForLast = { CT_Login.OperatorId, LastReceiveId };

            int return_value = -1, return_valuelast = -1;

            SqlTransaction update = null;
            try
            {
                strCmd = igetCmd.GetSQLCmd_ReturnForTableCurrentNotSend();

                if (TableLast != DefaultTableLast)
                {
                    igetCmd_CurrentReturn = ccc.GetISQLCmd(TableLast);
                }
                else
                {
                    igetCmd_CurrentReturn = igetCmd_DefaultReturnLast;
                }

                strCmdLast = igetCmd_CurrentReturn.GetSQLCmd_ReturnForTableLast();

                update = CT_Login.SqlDbCon.BeginTransaction();

                CSQL.ExecModel_Return_Trans(strCmd, paname, values, out return_value, CT_Login.SqlDbCon, ref update);

                CSQL.ExecModel_Return_Trans(strCmdLast, panameForLast, valuesForLast, out return_valuelast, CT_Login.SqlDbCon, ref update);

                return_value = return_valuelast + return_value;
                if (return_value == 2)
                {
                    update.Commit();
                    return true;
                }
                else
                {
                    update.Rollback();
                    string str = "回退失败！";
                    MessageBox.Show(str, "错误");
                    PException.Exception(str);
                    return false;
                }
            }
            catch (SqlException ser)
            {
                if (update != null)
                    update.Rollback();
                MessageBox.Show(ser.Message, "SQL错误");
                PException.Exception(ser.Message, ser);
                return false;
            }
            catch (Exception ex)
            {
                if (update != null)
                    update.Rollback();
                MessageBox.Show(ex.Message, "错误");
                PException.Exception(ex.Message, ex);
                return false;
            }
            finally
            {
                update = null;
            }
        }
        /// <summary>
        ///  退已发的：对当前表更新而且插入新行,下一表只更新;
        /// </summary>
        /// <param name="PatientFlowId"></param>
        /// <param name="iGroupId"></param>
        /// <param name="lreceiveId"></param>
        /// <returns></returns>
        private bool UpdateDataToReturnForSent(long lPatientFlowId, int iGroupId, long lreceiveId)
        {
            string strCmd = ""; string strCmdNext = "";
            string[] paname = { "OperatorId", "ReceiveId" };

            object[] values = { CT_Login.OperatorId, lreceiveId };

            string[] panameForNext = { "GroupId", "PatientFlowId", "OperatorId", "LReceiveId" };

            object[] valuesForNext = { iGroupId, lPatientFlowId, CT_Login.OperatorId, lreceiveId };
          
            int return_value = -1, return_valuenext = -1;

            SqlTransaction update = null;
            try
            {
                strCmd = igetCmd.GetSQLCmd_ReturnForTableCurrent();

                if (TableNext != DefaultTableNext)
                {
                    igetCmd_CurrentReturn = ccc.GetISQLCmd(TableNext);
                }
                else
                {
                    igetCmd_CurrentReturn = igetCmd_DefaultReturnNext;
                }
                 strCmdNext = igetCmd_CurrentReturn.GetSQLCmd_ReturnForTableNext();
   
                update = CT_Login.SqlDbCon.BeginTransaction();

                CSQL.ExecModel_Return_Trans(strCmd, paname, values, out return_value, CT_Login.SqlDbCon, ref update);

                CSQL.ExecModel_Return_Trans(strCmdNext, panameForNext, valuesForNext, out return_valuenext, CT_Login.SqlDbCon, ref update);

                return_value = return_valuenext + return_value;
                if (return_value == 2)
                {
                    update.Commit();
                    return true;
                }
                else
                {
                    update.Rollback();

                    string str = "";
                    if (return_valuenext == -2)
                    {
                        str = "请先让“发送操作员”回退。若不成功，请联系系统管理员处理！";//下一组没有可退的数据，请联系系统管理员处理
                    }
                     str += "回退已发送的信息失败！";
                    MessageBox.Show(str, "错误");
                    PException.Exception(str);
                    return false;
                }

            }
            catch (SqlException ser)
            {
                if (update != null)
                    update.Rollback();
                MessageBox.Show(ser.Message, "SQL错误");
                PException.Exception(ser.Message, ser);
                return false;
            }
            catch (Exception ex)
            {
                if (update != null)
                    update.Rollback();
                MessageBox.Show(ex.Message, "错误");
                PException.Exception(ex.Message, ex);
                return false;
            }
            finally
            {
                update = null;
            }
        }

        /// <summary>
        /// 检查是否已回退过该条数据
        /// </summary>
        /// <param name="lpfid"></param>
        /// <param name="igroupid"></param>
        /// <returns>false　已回退过。</returns>
        private bool  CheckReturnDataExists(long lpfid,int igroupid)
        {
            string strCmd = "";
            string[] paname = { "PatientFlowId", "GroupId" };

            object[] values = { lpfid, igroupid };
 
            int return_value = -1;
 
            try
            {
                strCmd = igetCmd.GetSQLCmd_ReturnForCheckExistsOfTableCurrent();
                 
                CSQL.ExecModel_Return(strCmd, paname, values, out return_value, CT_Login.SqlDbCon); 
 
                if (return_value >0)
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
            catch (SqlException ser)
            {
                MessageBox.Show(ser.Message, "SQL错误");
                PException.Exception(ser.Message, ser);
                return false;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "错误");
                PException.Exception(ex.Message, ex);
                return false;
            }
        }
        #endregion

        #region 上架按钮
         private void ExecUpToCirculate()
         {
             string strtip = "";
             int iCount = 0;
           iCount =  ExecUpToCirculate("CreateDataFromMRStatusForCirculate");
           iCount +=  ExecUpToCirculate("CreateDataFromMRStatusForCirculate_Other");

           if (iCount > 0)
             {
               strtip =  iCount.ToString() + "份病案　成功执行上架！";
             }
             else
             {
                 strtip = "没有任何病案执行上架！";
             }
             MessageBox.Show(strtip, "提示");
         }
        
        private int ExecUpToCirculate(string strCmd)
        {
            int return_count = -1,iCount =0;
            
            try
            {
                CSQL.ExecModel(strCmd, CT_Login.OperatorId, out return_count, CT_Login.SqlDbCon);
                if (return_count > 0)
                {
                    iCount = (int)(return_count / 4);
                }
               
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
                PException.Exception(ex.Message, ex); 
            }
            return iCount;
        }
        #endregion

        #region 回退方法

        private void ReturnSentButNextGroupNotReceivedData()
        {
            if (!CheckAndUpdateDataToReturnForDouble(DgSent, "bReturned_Sent", "NextGroupId_Sent", "PatientFlowId_Sent", "ReceiveId_Sent", "LastReceiveId_Sent", "LastOperatorId_Sent", true)) return;
             
            SentFind_NextGroupNotReceive();
        }

        private void ReturnReceivedNotSentData()
        {
            if (!CheckAndUpdateDataToReturn(DgCaseSend, "bReturned_Send", "LastGroupId_Send", "PatientFlowId", "ReceiveId_ForSend", "LastReceiveId_Send", "LastOperatorId_Send", false)) return;
           // SendFindForUI();
            ClearDataForUI();
        }

        private void InitDaSentCmd()
        {
            DaSent.SelectCommand.Parameters.Clear();
            DaSent.SelectCommand.CommandText = igetCmd.GetSQLCmd_SentFind();//"CTSENDFindCollectdCase";
            DaSent.SelectCommand.Parameters.Add("@OperatorId", SqlDbType.Int);
            DaSent.SelectCommand.Parameters["@OperatorId"].Value = CT_Login.OperatorId;
        }

        private void ReturnCase()
        {
            if (DgCaseSend.RowCount > 0)
            {
                string str = DgCaseSend["PatientName_Send", DgCaseSend.CurrentCell.RowIndex].FormattedValue.ToString();
                if (MessageBox.Show("回退完成后将清除窗口数据！你确定要回退“" + str + "”的信息吗？", "提示", MessageBoxButtons.OKCancel, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) == System.Windows.Forms.DialogResult.Cancel) return;
                ReturnReceivedNotSentDataAction();
            }
            else
            {
                MessageBox.Show("没有可回退的数据！", "提示");
            }
            tbxFind.Focus();
        }
 
        #endregion

        #region 其它方法
 
　　
        private void ClearData(DataTable dt)
        {
            if (dt.Rows.Count > 0)
            {
                dt.Clear();
                dt.AcceptChanges();
            }
        }
 
        private void ClearDataForUI()
        {
            if (tabControlEx1.SelectedIndex == 0)
            {
                ClearDataForUI(dsCaseManage.CollectCase, bsCaseReceive, cbxAllSelect, "bReceived");
                if (bDataIsFind_Receive) bDataIsFind_Receive = false;
            }
            else
            {
                ClearDataForUI(dsCaseManage.CheckScanCase, bSCaseSend, cbxSendSelectAll, "bSent");
                if (bDataIsFind_Send) bDataIsFind_Send = false;
            }
        }

        private void ClearDataForUI(DataTable dt,BindingSource bS,CheckBox cbx,string bColName)
        {
            object ovalue =DBNull.Value;
            int icount = 0;// dt.Rows.Count;
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                ovalue = dt.Rows[i][bColName];
                if (object.Equals(ovalue, true))
                    icount++;
            }
            if (icount > 0)
            {
                if (MessageBox.Show("你确定要清除已有数据吗？", "提示", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) == System.Windows.Forms.DialogResult.Cancel) return;
            }

            if (dt.Rows.Count > 0)
            {
                if (cbx.Checked)
                {
                    dt.Clear();
                    DeleteCount_Auto(icount);
                }
                else
                {
                    ClearFocusedRow(dt, bS);
                }

                dt.AcceptChanges();
            }
        }

        private   void ClearFocusedRow(DataTable dt, BindingSource bS,bool bFind)
        {
            if (bFind)
            {
                MessageBox.Show("查询数据，请直接清除!", "提示"); return;
            }
            ClearFocusedRow(dt, bS);
        }
        private  void ClearFocusedRow(DataTable dt, BindingSource bS)
        {
            int ipos = -1;

            ipos = bS.Position;

            if (ipos >= 0)
            {
                dt.Rows[ipos].Delete();
                DeleteCount_Auto(1);
            }
            dt.AcceptChanges();
        }

        private  void ClearFocusedRowForUI()
        {
            if (tabControlEx1.SelectedIndex == 0)
            {
                ClearFocusedRow(dsCaseManage.CollectCase, bsCaseReceive,bDataIsFind_Receive);
            }
            else
            {
                ClearFocusedRow(dsCaseManage.CheckScanCase, bSCaseSend,bDataIsFind_Send);
            }
        }

        private void DeleteCount_Auto(int iCount)
        {
            if (tabControlEx1.SelectedIndex == 0)
            {
                if (Count_AutoReceive > 0)
                    _Count_AutoReceive -= iCount;
            }
            else
            {
                if (Count_AutoSend > 0)
                    _Count_AutoSend -= iCount;
            }
        }

        internal bool FillData(SqlDataAdapter da, DataTable dtCaseReceive,DataTable dtReceived,BindingSource bs,int iDs)
        {
            try
            {
                switch (iDs)
                {
                    case 0://接收
                         
                        ClearData(dtReceived);
                        break;
                    case 1://需接收查询
                        ClearData(dtReceived);
                        break;
                    case 2://已接收
                        ClearData(dtCaseReceive);
                        break;
                    case 3://发送
                       
                        ClearData(dtReceived);
                        break;
                    case 4://需发送查询
                        ClearData(dtReceived);
                        break;
                    case 5://已发送
                        ClearData(dtReceived);
                        break;

                }
                FillDataOnly(da, dtReceived, bs);

                return true;
            }
            catch (SqlException se)
            {
                MessageBox.Show(se.Message, "填充数据");
                PException.Exception(se.Message, se);
                return false;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "填充数据");
                PException.Exception(ex.Message, ex);
                return false;

            }
        }

        private static void FillDataOnly(SqlDataAdapter da, DataTable dtReceived, BindingSource bs)
        {
            bs.Filter = "";
            da.AcceptChangesDuringFill = true;
            da.Fill(dtReceived);
            da.AcceptChangesDuringFill = false;
            dtReceived.AcceptChanges();
 
        }
 
        internal void FindData(SqlDataAdapter Da,int iDs)
        {
            BindingSource bs=null;
 
            switch(iDs)
            {
                case 0:
                    bs =bSReceived;// bsCaseReceive;
                    FillData(Da, dsCaseManage.CollectCase_Received, dsCaseManage.CollectCase_Received, bs, iDs);
                    break;
                case 1:
                    bs = bsCaseReceive;
                    FillData(Da, dsCaseManage.CollectCase, dsCaseManage.CollectCase, bs, iDs);
                    break;
                case 2:
                    bs =bSReceived; //bsCaseReceive;
                    FillData(Da, dsCaseManage.CollectCase_Received, dsCaseManage.CollectCase_Received, bs, iDs);
                    break;
                case 3:
                     bs =bsSent;
                    FillData(Da, dsCaseManage.BindingCase, dsCaseManage.BindingCase, bs, iDs);
                    break;
                case 4:
                    bs =bSCaseSend;
                    FillData(Da, dsCaseManage.CheckScanCase, dsCaseManage.CheckScanCase, bs, iDs);
                    break;
                case 5:
                    bs =bsSent;
                    FillData(Da, dsCaseManage.BindingCase, dsCaseManage.BindingCase, bs, iDs);
                    break;
            }
        }

        private void UpSelectRow(BindingSource Bs)
        {
            if (Bs.Count <= 0) return;
            Bs.MovePrevious();
        }

        private void DownSelectRow(BindingSource Bs)
        {
            if (Bs.Count <= 0) return;
            Bs.MoveNext();
        }

        private void GetCaseMistakeCount()
        {
            Dictionary<string, string> Dic = new Dictionary<string, string>();
            Dic.Add("OperateGroupId",CurrentGroupId.ToString());
            Dic.Add("TableName", CT_Login.TableCurrent);
            
            int ireturn = -1;
            CSQL.ExecModel_Return("CTGetCaseMistakeCount", Dic, out ireturn, CT_Login.SqlDbCon);

            CaseMistakeCount = ireturn;
            ireturn = -1;

            Dic.Add("MaxDays", CT_Login.MaxDaysIncludeHolidays.ToString());
            CSQL.ExecModel_Return("CTGetCaseOverDueCount",Dic, out ireturn, CT_Login.SqlDbCon);

            CaseOverDueCount = ireturn;
        }

        /// <summary>
        /// 处理并发错误
        /// </summary>
        /// <param name="dbcx"></param>
        private void createMessage(DBConcurrencyException dbcx)
        {

            // Declare variables to hold the row versions for display 
            // in the message box.
            string strerror = "错误有：";
            string strInDs = "旧记录(在前台的)\n";//"Original record in dsAuthors1:\n";
            string strInDB = "当前数据库中的记录\n";//"Current record in database:\n";
            string strProposed = "建议的修改:\n";//Proposed change:\n";
           // string strPromptText = "您是否愿意按“建议的修改”覆盖数据库中的记录?\n";//"Do you want to overwrite the current " + "record in the database with the proposed change?\n";
            string strMessage;
            //		System.Windows.Forms.DialogResult response;

            // Loop through the column values.

            // DataRow  Dspathogeny.PathogenyItemRegisterRow
            //DataRow rowInDB = this.dspathogeny.PathogenyItemRegister.FindByitemtotalid(long.Parse(dbcx.Row["itemtotalid"].ToString()));
            //if (object.Equals(rowInDB, null))
            //    rowInDB = this.dspathogeny.PathogenyResultR.FindByresultid(long.Parse(dbcx.Row["resultid"].ToString()));
            //if (object.Equals(rowInDB, null))
            string s = dbcx.StackTrace;
            DataRow rowInDB = this.dsCaseManage.CheckScanCase.FindByReceiveId(long.Parse(dbcx.Row["ReceiveId"].ToString()));
            bool berror = rowInDB.HasErrors;
            DataColumn[] A = rowInDB.GetColumnsInError();
            for (int X = 0; X < A.Length; X++)
            {
                strerror += " 第 " + X.ToString() + " errorcolname= " + A[X].ColumnName + " 值为" + A[X].ToString() + "\t";
            }
            for (int i = 0; i < dbcx.Row.ItemArray.Length; i++)
            {
                strInDs += dbcx.Row[i, DataRowVersion.Original] + "\t";
                strInDB += rowInDB[i, DataRowVersion.Current] + "\t";
                // strProposed += dbcx.Row[i, DataRowVersion.Current] + "\t";
            }

            // Create the message box text string.
            strMessage = strerror + "\n" + strInDs + "\n" + strInDB + "\n" + strProposed + "\n";
            // + strPromptText;

            // Display the message box.
            MessageBox.Show(strMessage, "保存失败");//
            //				MessageBoxButtons.YesNo);
            //			processResponse(response);
        }
 
        private void SetRowBackColor(DataGridViewRowPostPaintEventArgs e) //DataGridViewCellPaintingEventArgs
        {
            SetRowBackColor(e.RowIndex);
        }

        private void SetRowBackColor(int index)
        {
            try
            {
                if (index < 0) return;
                if (DBNull.Value.Equals(CT_Login.MaxWorkDays)) return;
                if (CT_Login.MaxWorkDays == 0) return;

                object oValue = DgCaseSend["OperateDate_Send", index].Value;
                if (DBNull.Value.Equals(oValue)) return;

                int  iday = DateTimeEx.DateDiff((DateTime)oValue,  DateTime.Now);
                int ioldv = iday;
 
                    if (iday <= (CT_Login.MaxDaysIncludeHolidays))
                    {
                        DgCaseSend.Rows[index].DefaultCellStyle.BackColor = Color.White;
                        DgCaseSend.Rows[index].DefaultCellStyle.SelectionBackColor = Color.FromKnownColor(KnownColor.Highlight);//默认：高亮蓝
                    }
                    else
                    {
                        if (CT_Login.TipBackColor != null)
                        {
                            DgCaseSend.Rows[index].DefaultCellStyle.BackColor = CT_Login.TipBackColor;
                            DgCaseSend.Rows[index].DefaultCellStyle.SelectionBackColor = CT_Login.TipBackColor;
                        }
                    }
                
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message + ex.StackTrace, "SetRowBackColor");
                PException.Exception(ex.Message + ex.StackTrace, ex);
            }
        }

        internal void ChangeBtnEnabled(bool bEnabled)
        {
            if (tabControlEx1.SelectedIndex == 0)
            {
                btnRecieve.Enabled = bEnabled;
            }
            else
            {
                btnSend.Enabled = bEnabled;
                cbbxNextGroup.Enabled = bEnabled;
                cbbxNextGroup.Refresh();
            }
        }
        #endregion
 
        #region DataGrid DataError

        private void DgSent_DataError(object sender, DataGridViewDataErrorEventArgs e)
        {
            GetNotValidError(e);
        }
        private void DgCaseReceive_DataError(object sender, DataGridViewDataErrorEventArgs e)
        {
            GetNotValidError(e);
        }
        private void DgReceived_DataError(object sender, DataGridViewDataErrorEventArgs e)
        {
            GetNotValidError(e);
        }
        private void DgCaseSend_DataError(object sender, DataGridViewDataErrorEventArgs e)
        {
            GetNotValidError(e);
        }
        private void DgCaseReceive_Validated(object sender, EventArgs e)
        {
            ExceptionNotValid();
        }
        private void DgSent_Validated(object sender, EventArgs e)
        {
            ExceptionNotValid();
        }
        private void DgReceived_Validated(object sender, EventArgs e)
        {
            ExceptionNotValid();
        }
 
        private void DgCaseSend_Validated(object sender, EventArgs e)
        {
            ExceptionNotValid();
        }
        #endregion

        #region Error方法
        private void GetNotValidError(DataGridViewDataErrorEventArgs e)
        {
            try
            {
                if (!e.Context.Equals(null))
                {
                    string str = "值无效";
                    string strmessage = e.Exception.Message;
                    if (strmessage.IndexOf(str) != -1)
                    {
                        strValid = strmessage;
                    }
                }
            }
            catch (ArgumentException ae)
            {
                MessageBox.Show(ae.Message, "");
                PException.Exception(ae.Message, ae);

            }
        }

        private void ExceptionNotValid()
        {
         if (strValid != "")
            {
            string str = "", str2 = "您需要重新设置各项的值，否则无法使用该数据系统！\n"
                + "(可能为“系统设置”中的“流程设置”被修改后引起)";
            if (strValid.IndexOf("ComboBoxCell") != -1)
            {
                str = "所在组或操作类别的值无效！";
            }
            MessageBox.Show(str2, str);
            PException.Exception(str + strValid + "。" + str2);
}
        }
        #endregion

        #region Iface
        public void RefreshData()
        {
            Init();
           InitData();
        }
        #endregion

        #region  Action
        #region part
        private bool ReceiveActionA()
        {
            if (TipNotOperate()) return false;
            if (!ReceiveDataBig()) return false;
            CheckAndUpdateDataToLastStep();

            //if (CT_Login.bDefaultFlow & CurrentGroupId == 5)
            //{
            //    FindData(DaReceive, 0);
            //}
            //else
            //{
               ClearData(dsCaseManage.CollectCase);
            //}
            InitDisplaylabel();
            return true;
             
        }

        private bool SendActionA()
        {
            if (TipNotOperate()) return false;
            if (!SendDataBig()) return false;
            CheckAndSendDataToNextStep();
          
            ClearData(dsCaseManage.CheckScanCase);
             
            tbxFind.Text = "";
            return true;
        }
 
        #endregion

        #region Receive
        internal void ReceiveAction()
        {
             ReceiveActionA();
        }

        private void RetrievalAction()
        {
            Retrieval();
            
            tbxReceiveBarCode.Focus();
        }
        #endregion

        #region UptoCirculate

        private void ExecUpToCirculateAction()
        {
            ExecUpToCirculate();
            ClearDataForUI();
        }
        #endregion

        #region Send
        private void SendAction()
        {
             SendActionA();
        }

        private void SendFindAction()
        {
            if (CT_Login.ReceiveOrSendType_Current == CT_Login.ReceiveOrSendType.ByGroup)
            {
                SendBeforeFindByGroup();
            }
            else
            {
                SendBeforeFindByOperator();
            }
         }
        #endregion

        #region Return
        /// <summary>
        /// Return By Button
        /// </summary>
        private void ReturnReceivedNotSentDataAction()
        {
             ReturnReceivedNotSentData();
         }
 
        /// <summary>
        /// Return Of Double Click
        /// </summary>
        /// <param name="p"></param>
        private void ReturnSentButNextGroupNotReceivedDataAction()
        {
             ReturnSentButNextGroupNotReceivedData();
         }
        #endregion
        #endregion
        #endregion

        #region 重复病案号信息处理
        private void dGRepeatCaseCodeInfo_DoubleClick(object sender, EventArgs e)
        {
            AddRowToDataGridControl(); 
        }

        private void dGRepeatCaseCodeInfo_KeyDown(object sender, KeyEventArgs e)
        {
            switch (e.KeyCode)
            {
                case Keys.Enter:
                    AddRowToDataGridControl();
                    break;
            }
        }
 
        private void dGRepeatCaseCodeInfo_Send_DoubleClick(object sender, EventArgs e)
        {
            AddRowToDataGridControl();
        }

        private void dGRepeatCaseCodeInfo_Send_KeyDown(object sender, KeyEventArgs e)
        {
            switch (e.KeyCode)
            {
                case Keys.Enter:
                    AddRowToDataGridControl();
                    break;
            }
        }

        private void tabControlEx1_Selecting(object sender, TabControlCancelEventArgs e)
        {
            if (DvPatientFlow != null)
            {
                if (DvPatientFlow.Count > 1)
                {
                    MessageBox.Show("请先处理重复信息！", "警告", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    e.Cancel = true;
                }
            }
        }
 
        public virtual void AddRowToDataGridControl()
        {
            if (tabControlEx1.SelectedIndex == 0)
            {
                DeleteNotSelectedInfo(dGRepeatCaseCodeInfo, "patientFlowId_Repeat");
                this.panelRepeatCaseCode.Visible = false;
                
                InsertNewRowForReceive(bSRepeat);
            }
            else
            {
                DeleteNotSelectedInfo(dGRepeatCaseCodeInfo_Send, "patientFlowId_Repeat_Send");
                this.panelRepeatCaseCode_Send.Visible = false;
                InsertNewRowForSend(bSRepeat);
            }
        }

        public  virtual void DeleteNotSelectedInfo(GridControlViewEx Dg, string strColName)
        {
            try
            {

               string strId = Dg.CurrentRow.Cells[strColName].Value.ToString();
                int iCount = DvPatientFlow.Count;
                for (int i = iCount - 1; i >= 0; i--)
                {
                    if (strId == DvPatientFlow[i]["PatientFlowId"].ToString())
                        continue;
                    else
                    {
                        DvPatientFlow[i].Delete();
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "删除错误");
                PException.Exception("DeleteNotSelectedInfo " + ex.Message, ex);
            }
        }

        #endregion

        #region Bak

        #region Barcode Methods
        private delegate void ShowInfoDelegate(BarCodeA.BarCodes barCode);

        private void ShowInfo(BarCodeA.BarCodes barCode)
        {
            if (this.InvokeRequired)
            {
                this.BeginInvoke(new ShowInfoDelegate(ShowInfo), new object[] { barCode });
            }
            else
            {

                //textBox1.Text = barCode.KeyName;

                //textBox2.Text = barCode.VirtKey.ToString();

                //textBox3.Text = barCode.ScanCode.ToString();

                //textBox4.Text = barCode.AscII.ToString();

                //textBox5.Text = barCode.Chr.ToString();

                //textBox6.Text = barCode.IsValid ? barCode.BarCode : "";
                StrBarCode = barCode.IsValid ? barCode.BarCode : "";
            }
        }

        void BarCode_BarCodeEvent(BarCodeA.BarCodes barCode)
        {
            ShowInfo(barCode);
        }
        #endregion




        #endregion
    }
}
