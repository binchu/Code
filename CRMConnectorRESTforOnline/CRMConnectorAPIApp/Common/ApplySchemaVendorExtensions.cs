using CRMConnectorAPIApp.Models;
using CRMRestService.Common;
using Swashbuckle.Swagger;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration;
using System.Threading;
using System.Xml;

namespace CRMConnectorAPIApp.Common
{
    public class ApplySchemaVendorExtensions : ISchemaFilter
    {
        public void Apply(Schema schema, SchemaRegistry schemaRegistry, Type type)
        {
            if (type != typeof(CRMResponse))
            {
                AddAttributes(ref schema, ref schemaRegistry);        
            }
        }

        private void AddAttributes(ref Schema schema, ref SchemaRegistry schemaRegistry)
        {
            schemaRegistry = RegistryComplicateSchema(schemaRegistry);

            if (string.IsNullOrEmpty(WebApiApplication.CrmModelString))
            {
                WebApiApplication.CrmModelString = GetCrmMetadata();
            }
            //get metadata
            XmlDocument xml = new XmlDocument();
            xml.LoadXml(WebApiApplication.CrmModelString);

            string entityName = ConfigurationManager.AppSettings["EntityName"];
            //get Entities
            XmlNodeList xnList = xml.GetElementsByTagName("EntityType");
            foreach (XmlNode xn in xnList)
            {
                string name = xn.Attributes.GetNamedItem("Name").Value;
                //find the entity we are looking for
                if (name == entityName)
                {
                    schema = AddSchema(schema, xn);
                    break;
                }
            }
            schema.properties.Add(Constants.PropertyName_Action, new Schema { type = "string" });
        }

        private SchemaRegistry RegistryComplicateSchema(SchemaRegistry schemaRegistry)
        {
            //build EntityReference Schema
            Schema schema1 = new Schema { type = "object" };
            IDictionary<string, Schema> id = new Dictionary<string, Schema>();
            schema1.properties = id;
            schema1.properties.Add("Id", new Schema { type = "string" });
            schema1.properties.Add("LogicalName", new Schema { type = "string" });

            //build OptionSet Schema  
            Schema schema2 = new Schema { type = "object" };
            IDictionary<string, Schema> id1 = new Dictionary<string, Schema>();
            schema2.properties = id1;
            schema2.properties.Add("Value", new Schema { type = "string" });

            schemaRegistry.Definitions.Add("EntityReference", schema1);
            schemaRegistry.Definitions.Add("OptionSet", schema2);
            return schemaRegistry;
        }

        private string GetCrmMetadata()
        {
            string modelString = string.Empty;
            CRMClient crmClient;
            if (ConfigurationManager.AppSettings["CRMVersion"] == "online")
                crmClient = new CRMClient(AuthenticationHelper.AuthToken(), ConfigurationManager.AppSettings["ida:CrmResourceURL"]);
            else
                crmClient = new CRMClient(AuthenticationHelper.GetHandler(), ConfigurationManager.AppSettings["ida:CrmResourceURL"]);

            //need to spin up a new thread to get the metadata
            Thread thread = new Thread(new ThreadStart(() => modelString = crmClient.GetMetaData().Result));
            thread.Start();
            thread.Join(95000 * 4);

            return modelString;
        }

        private Schema AddSchema(Schema schema, XmlNode xn)
        {
            ArrayList arraylist = GetProperties(xn);

            arraylist.Sort();
            foreach (Object obj in arraylist)
            {
                string str = obj.ToString();
                string[] strarray = str.Split(';');

                Schema newschema = new Schema { type = "string" };
                if (strarray[1].Contains("OptionSetValue"))
                {
                    newschema = new Schema { @ref = "OptionSet" };
                }
                else if (strarray[1].Contains("EntityReference"))
                {
                    newschema = new Schema { @ref = "EntityReference" };
                }

                schema.properties.Add(strarray[0], newschema);
            }

            return schema;
        }

        private ArrayList GetProperties(XmlNode xn)
        {
            ArrayList arraylist = new ArrayList();
            XmlNode entityNode = null;
            for (int i = 1; i <= xn.ChildNodes.Count; i++)
            {
                if (i == 1)
                {
                    entityNode = xn.FirstChild;
                }
                else
                {
                    entityNode = entityNode.NextSibling;
                    if (entityNode.Name == "Property")
                    {
                        string name = entityNode.Attributes.GetNamedItem("Name").Value;
                        string nodetype = entityNode.Attributes.GetNamedItem("Type").Value;
                        arraylist.Add(name + ";" + nodetype);
                    }
                }
            }
            return arraylist;
        }

    }
}