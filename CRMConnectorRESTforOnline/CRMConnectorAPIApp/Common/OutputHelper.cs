using CRMConnectorAPIApp.Models;
using CRMRestService.Common;
using Newtonsoft.Json.Linq;
using System;
using System.Configuration;

namespace CRMConnectorAPIApp.Common
{
    public static class OutputHelper
    {
        private static string crmPrimaryKey = ConfigurationManager.AppSettings["EntityName"].ToString() + "Id";
        private static string crmSecondKey = ConfigurationManager.AppSettings["CrmSecondPrimaryKey"].ToString();

        public static CRMResponse InvalidResponse(JObject input)
        {
            CRMResponse response = new CRMResponse()
            {
                InputData = input.ToString(),
                RecordGuid = input.Property(crmPrimaryKey) != null ? Guid.Parse(input.Value<string>(crmPrimaryKey)) : Guid.Empty,
                LogStatusCode = Constants.CRMFailed,
                MessageText = "input object error: " + input.ToString()
            };

            return response;
        }

        public static CRMResponse FailedResponse(JObject input, Exception ex)
        {
            CRMResponse response = new CRMResponse()
            {
                InputData = input.ToString(),
                RecordGuid = Guid.Parse(input.Value<string>(crmPrimaryKey)),
                LogStatusCode = Constants.CRMFailed,
                MessageText = ex.Message + (ex.InnerException == null ? string.Empty : "InnerException: " + ex.InnerException.Message)
            };

            return response;
        }

        public static CRMResponse SuccessResponse(JObject input)
        {
            CRMResponse response = new CRMResponse()
            {
                InputData = input.ToString(),
                RecordGuid = Guid.Parse(input.Value<string>(crmPrimaryKey)),
                LogStatusCode = Constants.CRMSucceed,
                MessageText = (int.Parse(input.Value<string>(Constants.PropertyName_Action)) == Constants.CRMCreate) ? "Created Successfully" : "Updated Successfully"
            };

            return response;
        }

    }
}