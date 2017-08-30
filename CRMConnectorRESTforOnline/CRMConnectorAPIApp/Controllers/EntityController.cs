using System;
using System.Linq;
using System.Web.Http;
using System.Configuration;
using Newtonsoft.Json.Linq;
using CRMConnectorAPIApp.Models;
using CRMConnectorAPIApp.Common;
using CRMRestService.Repositry;
using CRMRestService.Common;
using CRMRestService.Models;
using log4net;
using System.Collections.Generic;

namespace CRMConnectorAPIApp.Controllers
{
    public class EntityController : ApiController
    {
        private string crmPrimaryKey = ConfigurationManager.AppSettings["EntityName"].ToString() + "Id";
        private string crmSecondPrimaryKey = ConfigurationManager.AppSettings["CrmSecondPrimaryKey"].ToString();

        public string Get()
        {
            return "API accessable.";
        }

        public CRMResponse Post([FromBody] object input)
        {
            ILog log = LogManager.GetLogger(typeof(ApiController));
            log.Info(string.Format("[Information]: Receive request. {0}", DateTime.Now.ToString()));
            var entityObj = input as JObject;
            if (!ValidateInput(entityObj))
                return OutputHelper.InvalidResponse(entityObj);
            log.Info("[Information]: Validation complete.");

            try
            {
                ServiceSetting setting = new ServiceSetting();
                if (setting.MicrosoftAccountEnabled)
                    setting.CacheAccountId = WebApiApplication.accountId;
                var crmRepositry = RepositryBase.CreateRepositry(setting);
                //crmRepositry.AssociateAccountId = WebApiApplication.accountId;

                log.Info(string.Format("[Information]: Start processing to CRM. {0}", DateTime.Now.ToString()));
                crmRepositry.Execute(entityObj);
                if (setting.MicrosoftAccountEnabled)
                    WebApiApplication.accountId = crmRepositry.AssociateAccountId;

                log.Info(string.Format("[Information]: Finish processing to CRM. {0}", DateTime.Now.ToString()));
                return OutputHelper.SuccessResponse(entityObj);
            }
            catch (Exception ex)
            {
                log.Info(string.Format("[Information]: Original Data. {0}", entityObj.ToString()));
                log = LogManager.GetLogger(ex.GetType());
                log.Error("[Exception]:", ex);

                return OutputHelper.FailedResponse(entityObj, ex);
            }
        }

        private bool ValidateInput(JObject input)
        {
            bool valid = true;

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
                if (input.Properties().Where(p => p.Value.Type == JTokenType.Object).Count() > 0)
                {
                    List<JProperty> temp = input.Properties().Where(p => p.Value.Type == JTokenType.Object).ToList();
                    foreach (JProperty property in temp)
                    {
                        if (property.Value.Values().Count() > 1 && string.IsNullOrEmpty(property.Value.Value<string>("Id")))
                            input.Property(property.Name).Remove();
                    }
                }
            }
            else
                valid = false;

            return valid;
        }

    }
}
