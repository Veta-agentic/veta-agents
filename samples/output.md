### 🤖 Response

You're experiencing an issue with the \"Get Advisor Score\" table not refreshing on the Infrastructure dashboard you have in the desktop version. After reviewing your question and the provided details, here is a summary of recommended solutions:

#### Steps to troubleshoot the issue:
1. **Update to the Latest Dashboard Version**
- Verify that the version of the dashboard matches the latest template from [Azure/CCOInsights GitHub repository](https://github.com/Azure/CCOInsights).
- The table format seems different from versions shown in current tutorials, indicating either an old or modified version.
2. **Refresh the Data Source**
- Ensure the dataset linked to the advisor score table is actively pulling the latest data. In Power BI, check Data Refresh options under settings.
3. **Check Permissions**
- Confirm that you have permissions to interact with and refresh the report. If it was shared, limited permissions may be causing the issue.
4. **Verify Filters and Queries**
- Inspect any filters or slice settings applied on the table. They might be restricting visible data.
- If you're familiar with the underlying dataset query or script, ensure that it is error-free and properly configured.
#### Next Steps:
- Review deployment and troubleshooting guides:
- [CCOInsights Deployment Guide](https://github.com/Azure/CCOInsights)
- [CCOInsights Troubleshooting Guide](https://github.com/Azure/CCOInsights/issues)
- If the issue persists, reach out to the GitHub repository's issues section to raise your concern.

Let me know if you need further details or instructions about any of these steps!


### 📝 Wiki References

- [Azure/CCOInsights Deployment Guide](https://github.com/Azure/CCOInsights)
- [Azure/CCOInsights Troubleshooting Guide](https://github.com/Azure/CCOInsights)
- [GitHub Repository - Azure/CCOInsights](https://github.com/Azure/CCOInsights)

### 🖼️ Context of the Image Provided
        
The image appears to show the \"Get Advisor Score\" table within the Infrastructure dashboard, but it reflects a different version or configuration compared to what's seen in Azure's tutorial videos. The issue might stem from discrepancies in versions or data source compatibility.

### 🔗 Similar Issues

Unfortunately, no resolved issues matching this case were found in the GitHub repository issues section. Consider raising a new issue at:
- [Azure/CCOInsights Open Issues](https://github.com/Azure/CCOInsights/issues)
Let me know if you need additional assistance!