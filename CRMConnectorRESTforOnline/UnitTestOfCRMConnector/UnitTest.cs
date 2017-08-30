using System;
using System.Configuration;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Diagnostics;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using CRMConnectorAPIApp.Common;
using CRMConnectorAPIApp.Models;
using CRMConnectorAPIApp;
using Newtonsoft.Json.Linq;
using CRMRestService.Repositry;
using CRMRestService.Common;
using CRMRestService.Models;

namespace UnitTestOfCRMConnector
{
    [TestClass]
    public class UnitTest
    {
        [TestMethod]
        public void TestAuth()
        {
            var token = AuthenticationHelper.AuthToken();
            var httpClient = new HttpClient();
            httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            string url = "https://dynplatformdev.crm.dynamics.com/XRMServices/2011/OrganizationData.svc/";
            HttpRequestMessage req = new HttpRequestMessage(HttpMethod.Get, url);
            var response = httpClient.SendAsync(req);
            response.Wait();
            Assert.IsTrue(response.Result.IsSuccessStatusCode);
            var content = response.Result.Content.ReadAsStringAsync();
            content.Wait();
            Debug.Write(content.Result);
            Assert.IsFalse(content.Result.Contains("Sign in to Dynamics CRM Online"));
        }

        #region onprem repositry
        [TestMethod]
        public void TestOnpremRepositryExecute_Contact()
        {
            /*
            <add key="EntityName" value="Contact"/>
            <add key="CrmPrimaryKey" value ="ContactId"/>
            <add key="CrmSecondPrimaryKey" value ="EmployeeId"/> 
            */
            //insert contact
            Random ran = new Random();
            int employeeid = ran.Next(2000000);
            string inputJsonData = "{\"Action\":\"0\",\"ContactId\":\"" + Guid.Empty.ToString() + "\",\"EmployeeId\":\"" + employeeid.ToString() + "\",\"FirstName\":\"Kevin\",\"LastName\":\"Lewis\",\"MiddleName\":\"\",\"MobilePhone\":\"\",\"JobTitle\":\"\",\"EMailAddress1\":\"V-KELE@microsoft.com\",\"Address1_City\":\"Santa Clara\",\"Address1_Country\":\"United States\",\"Address1_StateOrProvince\":\"CA\",\"Telephone1\":\"\",\"Address1_Line1\":\"2045 Lafayette Street\",\"Address1_Line3\":\"\",\"Address1_PostalCode\":\"95050\"}";
            //string inputJsonData = "{\"ContactId\": \"\",\"EMailAddress1\": \"V-TILEON@microsoft.com\",\"EMailAddress2\": \"v-tileon@microsoft.com\",\"EmployeeId\": \"1352109318\",\"FirstName\": \"kanchen\",\"LastName\": \"Leon-Dufour\",\"MiddleName\": \"\",\"new_CostCenter\": \"IE-WWL International Dublin\",\"new_CostCenterCode\": \"24069\",\"new_CostCenterNumber\": \"24069\",\"new_Domain\": \"EUROPE\",\"new_DomainAlias\": \"EUROPE\\\\v-tileon\",\"new_MSAlias\": \"v-tileon\",\"new_PositionNumber\": \"91250771\",\"new_ReportsToPositionNumber\": \"8143\",\"StateCode\": {\"Value\": 0},\"StatusCode\": {\"Value\": 1}}";
            //string inputJsonData = "{\"FirstName\":\"KevinKK\"}";
            var obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            var task = OnpremTest(obj);

            CRMResponse res = task;
            Assert.IsNotNull(res.RecordGuid);
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
            Guid guid = res.RecordGuid;
            // update contact without given guid
            inputJsonData = "{\"Action\":\"1\",\"ContactId\":null,\"EmployeeId\":\"" + employeeid.ToString() + "\",\"FirstName\":\"KanChen0\",\"LastName\":\"Lewis\",\"MiddleName\":\"\",\"MobilePhone\":\"\",\"JobTitle\":\"\",\"EMailAddress1\":\"V-KELE@microsoft.com\",\"Address1_City\":\"Santa Clara\",\"Address1_Country\":\"United States\",\"Address1_StateOrProvince\":\"CA\",\"Telephone1\":\"\",\"Address1_Line1\":\"2045 Lafayette Street\",\"Address1_Line3\":\"\",\"Address1_PostalCode\":\"95050\",\"StateCode\":{\"Value\":\"1\"},\"StatusCode\":{\"Value\":\"2\"}}";
            obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            task = OnpremTest(obj);

            res = task;
            Assert.IsNotNull(res.RecordGuid);
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
            Assert.AreEqual(res.RecordGuid, guid);
            // update contact
            inputJsonData = "{\"Action\":\"1\",\"ContactId\":\"" + res.RecordGuid.ToString() + "\",\"EmployeeId\":\"" + employeeid.ToString() + "\",\"FirstName\":\"KanChen1\",\"LastName\":\"Lewis\",\"MiddleName\":\"\",\"MobilePhone\":\"\",\"JobTitle\":\"\",\"EMailAddress1\":\"V-KELE@microsoft.com\",\"Address1_City\":\"Santa Clara\",\"Address1_Country\":\"United States\",\"Address1_StateOrProvince\":\"CA\",\"Telephone1\":\"\",\"Address1_Line1\":\"2045 Lafayette Street\",\"Address1_Line3\":\"\",\"Address1_PostalCode\":\"95050\"}";
            obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            task = OnpremTest(obj);
            res = task;
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
        }

        private CRMResponse OnpremTest(JObject entityObj)
        {
            if (!ValidateInput(entityObj))
                return OutputHelper.InvalidResponse(entityObj);
            try
            {
                ServiceSetting setting = new ServiceSetting();
                setting.CRMVersion = "onprem";
                setting.MicrosoftAccountEnabled = false;
                setting.CrmResourceURL = "https://azcrmuextwb01.partners.extranet.microsoft.com/OnePayrollUAT041115";
                setting.User = "redmond\\ccrmdeva";
                setting.Password = "C!0udcrmA((0unt";

                var crmRepositry = RepositryBase.CreateRepositry(setting);

                crmRepositry.Execute(entityObj);

                return OutputHelper.SuccessResponse(entityObj);
            }
            catch (Exception ex)
            {
                return OutputHelper.FailedResponse(entityObj, ex);
            }
        }
        #endregion

        #region online repositry
        [TestMethod]
        public void TestRepositryExecute_Contact()
        {
            /*
            <add key="EntityName" value="Contact"/>
            <add key="CrmPrimaryKey" value ="ContactId"/>
            <add key="CrmSecondPrimaryKey" value ="EmployeeId"/> 
            */
            //insert contact
            Random ran = new Random();
            int employeeid = ran.Next(2000000);
            string inputJsonData = "{\"Action\":\"0\",\"ContactId\":\"" + Guid.Empty.ToString() + "\",\"EmployeeId\":\"" + employeeid.ToString() + "\",\"FirstName\":\"Kevin\",\"LastName\":\"Lewis\",\"MiddleName\":\"\",\"MobilePhone\":\"\",\"JobTitle\":\"\",\"EMailAddress1\":\"V-KELE@microsoft.com\",\"Address1_City\":\"Santa Clara\",\"Address1_Country\":\"United States\",\"Address1_StateOrProvince\":\"CA\",\"Telephone1\":\"\",\"Address1_Line1\":\"2045 Lafayette Street\",\"Address1_Line3\":\"\",\"Address1_PostalCode\":\"95050\"}";
            //string inputJsonData = "{\"ContactId\": \"\",\"EMailAddress1\": \"V-TILEON@microsoft.com\",\"EMailAddress2\": \"v-tileon@microsoft.com\",\"EmployeeId\": \"1352109318\",\"FirstName\": \"kanchen\",\"LastName\": \"Leon-Dufour\",\"MiddleName\": \"\",\"new_CostCenter\": \"IE-WWL International Dublin\",\"new_CostCenterCode\": \"24069\",\"new_CostCenterNumber\": \"24069\",\"new_Domain\": \"EUROPE\",\"new_DomainAlias\": \"EUROPE\\\\v-tileon\",\"new_MSAlias\": \"v-tileon\",\"new_PositionNumber\": \"91250771\",\"new_ReportsToPositionNumber\": \"8143\",\"StateCode\": {\"Value\": 0},\"StatusCode\": {\"Value\": 1}}";
            //string inputJsonData = "{\"FirstName\":\"KevinKK\"}";
            var obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            var task = OnlineTest(obj);

            CRMResponse res = task;
            Assert.IsNotNull(res.RecordGuid);
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
            Guid guid = res.RecordGuid;
            // update contact without given guid
            inputJsonData = "{\"Action\":\"1\",\"ContactId\":null,\"EmployeeId\":\"" + employeeid.ToString() + "\",\"FirstName\":\"KanChen0\",\"LastName\":\"Lewis\",\"MiddleName\":\"\",\"MobilePhone\":\"\",\"JobTitle\":\"\",\"EMailAddress1\":\"V-KELE@microsoft.com\",\"Address1_City\":\"Santa Clara\",\"Address1_Country\":\"United States\",\"Address1_StateOrProvince\":\"CA\",\"Telephone1\":\"\",\"Address1_Line1\":\"2045 Lafayette Street\",\"Address1_Line3\":\"\",\"Address1_PostalCode\":\"95050\",\"StateCode\":{\"Value\":\"1\"},\"StatusCode\":{\"Value\":\"2\"}}";
            obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            task = OnlineTest(obj);

            res = task;
            Assert.IsNotNull(res.RecordGuid);
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
            Assert.AreEqual(res.RecordGuid, guid);
            // update contact
            inputJsonData = "{\"Action\":\"1\",\"ContactId\":\"" + res.RecordGuid.ToString() + "\",\"EmployeeId\":\"" + employeeid.ToString() + "\",\"FirstName\":\"KanChen1\",\"LastName\":\"Lewis\",\"MiddleName\":\"\",\"MobilePhone\":\"\",\"JobTitle\":\"\",\"EMailAddress1\":\"V-KELE@microsoft.com\",\"Address1_City\":\"Santa Clara\",\"Address1_Country\":\"United States\",\"Address1_StateOrProvince\":\"CA\",\"Telephone1\":\"\",\"Address1_Line1\":\"2045 Lafayette Street\",\"Address1_Line3\":\"\",\"Address1_PostalCode\":\"95050\"}";
            obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            task = OnlineTest(obj);
            res = task;
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
        }

        [TestMethod]
        public void TestRepositryExecute_Account()
        {
            /*
            <add key="EntityName" value="new_gl04account"/>
            <add key="CrmPrimaryKey" value ="new_gl04accountId"/>
            <add key="CrmSecondPrimaryKey" value ="new_AccountCode"/>
            */
            //insert GL04 Account
            Random ran = new Random();
            int accountcode = ran.Next(2000000);
            string inputJsonData = "{\"Action\":\"0\",\"new_gl04accountId\":\"" + Guid.Empty.ToString() + "\",\"new_AccountCode\":\"" + accountcode.ToString() + "\",\"new_AccountShortDesc\":\"kanchen\"}";
            var obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            var task = OnlineTest(obj);
            CRMResponse res = task;
            Assert.IsNotNull(res.RecordGuid);
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
            Guid guid = res.RecordGuid;
            //update without given guid
            inputJsonData = "{\"Action\":\"1\",\"new_gl04accountId\":null,\"new_AccountCode\":\"" + accountcode.ToString() + "\",\"new_AccountShortDesc\":\"kanchen1\"}";
            obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            task = OnlineTest(obj);
            res = task;
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
            Assert.IsNotNull(res.RecordGuid);
            Assert.AreEqual(res.RecordGuid, guid);
            //update with guid
            inputJsonData = "{\"Action\":\"1\",\"new_gl04accountId\":\"" + guid.ToString() + "\",\"new_AccountCode\":\"" + accountcode.ToString() + "\",\"new_AccountShortDesc\":\"kanchen2\"}";
            obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            task = OnlineTest(obj);
            res = task;
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));

        }

        [TestMethod]
        public void TestRepositryExecute_InternalOrder()
        {
            /*
            <add key="EntityName" value="new_internalorder"/>
            <add key="CrmPrimaryKey" value ="new_internalorderId"/>
            <add key="CrmSecondPrimaryKey" value ="new_InternalOrderNumber"/>
            */
            //insert internal order
            Random ran = new Random();
            int accountcode = ran.Next(2000000);
            string inputJsonData = "{\"Action\":\"0\",\"new_internalorderId\":\"" + Guid.Empty.ToString() + "\",\"new_InternalOrderNumber\":\"" + accountcode.ToString() + "\",\"new_name\":\"kanchen\"}";

            var obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            var task = OnlineTest(obj);
            CRMResponse res = task;
            Assert.IsNotNull(res.RecordGuid);
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
            Guid guid = res.RecordGuid;
            //update without given guid
            inputJsonData = "{\"Action\":\"1\",\"new_internalorderId\":null,\"new_InternalOrderNumber\":\"" + accountcode.ToString() + "\",\"new_name\":\"kanchen1\"}";
            obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            task = OnlineTest(obj);
            res = task;
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
            Assert.IsNotNull(res.RecordGuid);
            Assert.AreEqual(res.RecordGuid, guid);
            //update with guid
            inputJsonData = "{\"Action\":\"1\",\"new_internalorderId\":\"" + guid.ToString() + "\",\"new_InternalOrderNumber\":\"" + accountcode.ToString() + "\",\"new_name\":\"kanchen2\"}";
            obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            task = OnlineTest(obj);
            res = task;
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));

        }
        private CRMResponse OnlineTest(JObject entityObj)
        {
            if (!ValidateInput(entityObj))
                return OutputHelper.InvalidResponse(entityObj);
            try
            {
                ServiceSetting setting = new ServiceSetting();
                setting.CRMVersion = "online";
                setting.MicrosoftAccountEnabled = true;
                setting.CrmResourceURL = "https://mpctest.crm.dynamics.com/";
                setting.User = "ccrmdeva@microsoft.com";
                setting.Password = "C!0udcrmA((0unt";

                setting.CacheAccountId = WebApiApplication.accountId;
                var crmRepositry = RepositryBase.CreateRepositry(setting);
                //crmRepositry.AssociateAccountId = WebApiApplication.accountId;

                crmRepositry.Execute(entityObj);
                WebApiApplication.accountId = crmRepositry.AssociateAccountId;

                return OutputHelper.SuccessResponse(entityObj);
            }
            catch (Exception ex)
            {
                return OutputHelper.FailedResponse(entityObj, ex);
            }
        }
        #endregion

        #region associate account
        [TestMethod]
        public void TestAccount()
        {
            Random ran = new Random();
            int name = ran.Next(2000000);   
            Guid accountId = Guid.Empty;

            CRMClient crmClient = new CRMClient(AuthenticationHelper.AuthToken(), ConfigurationManager.AppSettings["ida:CrmResourceURL"]);  
            var task = crmClient.ReadData("Account", "Name","microsoft", "AccountId");
            task.Wait();
            string result = task.Result;
            if (result.IndexOf("guid") != -1)
            {
                accountId = new Guid(result.Substring(result.IndexOf("guid") + 5, 36));
                Assert.AreNotEqual(Guid.Empty, accountId);
            }
            accountId = Guid.NewGuid();
            string jsonData = "{\"AccountId\":\"" + accountId.ToString() + "\",\"Name\":\""+name.ToString()+"\"}";
            task = crmClient.CreateData(jsonData, "Account");
            task.Wait();
            result = task.Result;
            task = crmClient.ReadData("Account", "Name",name.ToString(), "AccountId");
            task.Wait();
            result = task.Result;
            Assert.AreNotEqual(-1, result.IndexOf("guid"));
            Guid guid = new Guid(result.Substring(result.IndexOf("guid") + 5, 36));
            Assert.IsNotNull(guid);
            Assert.AreEqual(accountId, guid);            
        }

        [TestMethod]
        public void TestAddAccount()
        {
            Random ran = new Random();
            int employeeid = ran.Next(2000000);
            string inputJsonData = "{\"Action\":\"0\",\"ContactId\":\"" + Guid.Empty.ToString() + "\",\"EmployeeId\":\"" + employeeid.ToString() + "\",\"FirstName\":\"KanKan\",\"LastName\":\"Lewis\"}";
            var obj = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(inputJsonData);
            var task = OnlineTest(obj);
            CRMResponse res = task;
            Assert.IsNotNull(res.RecordGuid);
            Assert.IsTrue(Convert.ToBoolean(res.LogStatusCode));
        }
        #endregion


        private bool ValidateInput(JObject input)
        {
            bool valid = true;
             string crmPrimaryKey = ConfigurationManager.AppSettings["EntityName"].ToString() + "Id";
         string crmSecondPrimaryKey = ConfigurationManager.AppSettings["CrmSecondPrimaryKey"].ToString();


            if (input.Properties().Count() > 0)
            {
                if (input.Properties().Where(p => p.Name == Constants.PropertyName_Action).Count() == 0 || string.IsNullOrEmpty(input.Value<string>(Constants.PropertyName_Action)))
                    valid = false;
                else if (input.Properties().Where(p => p.Name == crmPrimaryKey).Count() == 0)
                    valid = false;
                else if (!string.IsNullOrEmpty(crmSecondPrimaryKey) && (input.Properties().Where(p => p.Name == crmSecondPrimaryKey).Count() == 0 || string.IsNullOrEmpty(input.Value<string>(crmSecondPrimaryKey))))
                    valid = false;

                if (string.IsNullOrEmpty(input.Value<string>(crmPrimaryKey)))
                    input.Property(crmPrimaryKey).Value = Guid.Empty.ToString();
            }
            else
                valid = false;

            return valid;
        }
    }
}
