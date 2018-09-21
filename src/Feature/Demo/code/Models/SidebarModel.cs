﻿namespace Sitecore.HabitatHome.Feature.Demo.Models
{
    using Sitecore.HabitatHome.Foundation.DependencyInjection;
    using Sitecore.XA.Foundation.Mvc.Models;

    [Service(Lifetime = Lifetime.Transient)]
    public class SidebarModel : RenderingModelBase
    {
        public Visits Visits { get; set; }
        public PersonalInfo PersonalInformation { get; set; }
        public OnsiteBehavior OnsiteBehavior { get; set; }
        public Referral Referral { get; set; }
        public bool IsActive { get; set; }
    }
}