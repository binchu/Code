using System;
using System.Web.Http;

namespace CRMConnectorAPIApp
{
    public class WebApiApplication : System.Web.HttpApplication
    {
        #region Global properties
        public static string CrmModelString;
        public static Guid accountId = Guid.Empty;
        #endregion

        protected void Application_Start()
        {
            GlobalConfiguration.Configure(WebApiConfig.Register);
        }
    }
}
