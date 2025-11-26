from opentelemetry import trace


class AgentConsumption:
    def __init__(self, agent_name: str, prompt_tokens: str, completion_tokens: str):
        self.agent_name = agent_name
        self.prompt_tokens = prompt_tokens
        self.completion_tokens = completion_tokens


class TokenConsumptionManager:
    def __init__(self):
        self.token_consumption_list: list[AgentConsumption] = []
        self.total_prompt_tokens = 0
        self.total_completion_tokens = 0
        self.tracer = trace.get_tracer(__name__)

    def add_token_consumption(self, agent_name: str, prompt_tokens: str, completion_tokens: str) -> None:
        self.token_consumption_list.append(
            AgentConsumption(
                agent_name=agent_name,
                prompt_tokens=prompt_tokens,
                completion_tokens=completion_tokens,
            )
        )
        self.total_prompt_tokens += int(prompt_tokens)
        self.total_completion_tokens += int(completion_tokens)
        with self.tracer.start_as_current_span("agent_tokens_consumption_" + agent_name) as span:
            span.set_attribute("prompt_tokens", prompt_tokens)
            span.set_attribute("completion_tokens", completion_tokens)
