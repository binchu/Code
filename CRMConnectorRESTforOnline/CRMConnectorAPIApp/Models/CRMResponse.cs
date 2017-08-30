using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace CRMConnectorAPIApp.Models
{
    public class CRMResponse
    {
        public Guid RecordGuid { get; set; }
        public int LogStatusCode { get; set; }
        public string MessageText { get; set; }

        public string InputData { get; set; }
    }
}