﻿// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using Azure.Core;

namespace Azure.ResourceManager
{
    /// <summary>
    /// A class representing Azure resource manager client options.
    /// </summary>
#pragma warning disable AZC0008 // ClientOptions should have a nested enum called ServiceVersion
    public sealed class ArmClientOptions : ClientOptions
#pragma warning restore AZC0008 // ClientOptions should have a nested enum called ServiceVersion
    {
        internal IDictionary<ResourceType, string> ResourceApiVersionOverrides { get; } = new Dictionary<ResourceType, string>();

        /// <summary>
        /// Gets or sets Azure cloud environment.
        /// </summary>
        public ArmEnvironment Environment { get; set; } = ArmEnvironment.AzureCloud;

        /// <summary>
        /// Sets the api version to use for a given resource type.
        /// </summary>
        /// <param name="resourceType"> The resource type to set the version for. </param>
        /// <param name="apiVersion"> The api version to use. </param>
        public void SetApiVersion(ResourceType resourceType, string apiVersion)
        {
            Argument.AssertNotNullOrEmpty(apiVersion, nameof(apiVersion));

            ResourceApiVersionOverrides[resourceType] = apiVersion;
        }
    }
}
