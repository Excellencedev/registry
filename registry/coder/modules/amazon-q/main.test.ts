import { describe, it, expect } from "bun:test";
import {
  runTerraformApply,
  runTerraformInit,
  testRequiredVariables,
  findResourceInstance,
} from "~test";
import path from "path";

const moduleDir = path.resolve(__dirname);

const requiredVars = {
  agent_id: "dummy-agent-id",
  experiment_auth_tarball: "dummy-auth-tarball",
};

describe("amazon-q module", async () => {
  await runTerraformInit(moduleDir);

  // 1. Required variables
  testRequiredVariables(moduleDir, requiredVars);

  // 2. coder_script resource is created
  it("creates coder_script resource", async () => {
    const state = await runTerraformApply(moduleDir, requiredVars);
    const scriptResource = findResourceInstance(state, "coder_script");
    expect(scriptResource).toBeDefined();
    expect(scriptResource.agent_id).toBe(requiredVars.agent_id);
    // Optionally, check that the script contains expected lines
    expect(scriptResource.script).toContain("Installing Amazon Q");
  });

  // 3. coder_app resource is created
  it("creates coder_app resource", async () => {
    const state = await runTerraformApply(moduleDir, requiredVars);
    const appResource = findResourceInstance(state, "coder_app", "amazon_q");
    expect(appResource).toBeDefined();
    expect(appResource.agent_id).toBe(requiredVars.agent_id);
  });

  // 4. AgentAPI integration
  it("creates AgentAPI module when enabled", async () => {
    const varsWithAgentAPI = {
      ...requiredVars,
      install_agentapi: true,
      web_app_display_name: "Amazon Q",
    };
    const state = await runTerraformApply(moduleDir, varsWithAgentAPI);
    
    // Check that the legacy app is not created when AgentAPI is enabled
    const legacyAppResource = findResourceInstance(state, "coder_app", "amazon_q");
    expect(legacyAppResource.count).toBe(0);
    
    // Check that AgentAPI module resources are created
    const agentapiScriptResource = findResourceInstance(state, "module.agentapi.coder_script");
    expect(agentapiScriptResource).toBeDefined();
    
    const agentapiAppResource = findResourceInstance(state, "module.agentapi.coder_app", "web");
    expect(agentapiAppResource).toBeDefined();
  });

  // 5. Task reporting integration
  it("creates coder_ai_task resource when task reporting is enabled", async () => {
    const varsWithTasks = {
      ...requiredVars,
      install_agentapi: true,
      web_app_display_name: "Amazon Q",
      experiment_report_tasks: true,
    };
    const state = await runTerraformApply(moduleDir, varsWithTasks);
    
    const taskResource = findResourceInstance(state, "coder_ai_task");
    expect(taskResource).toBeDefined();
    expect(taskResource.app_slug).toBe("amazon-q");
  });

  // Add more state-based tests as needed
});
