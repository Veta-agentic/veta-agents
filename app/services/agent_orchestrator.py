import logging

from semantic_kernel.agents import AgentGroupChat
from semantic_kernel.agents.strategies import TerminationStrategy
from semantic_kernel.contents.chat_message_content import ChatMessageContent

from app.agents.exceptions.exception_agent import ExceptionsAgent
from app.agents.images.images_agent import ImagesAgent
from app.agents.issues.issues_agent import IssuesAgent
from app.agents.issues_creation.issues_creation_agent import IssuesCreationAgent
from app.agents.reviewer_agent import ReviewerAgent
from app.agents.wikis.wiki_agent import WikiAgent
from app.core.config_factory import get_config
from app.models import ExceptionWatchRequestModel, RequestModel
from app.services.agent_contracts import ResponseMessage
from app.services.token_consumption import TokenConsumptionManager

config = get_config()


class ApprovalTerminationStrategy(TerminationStrategy):
    """A strategy for determining when an agent should terminate."""

    async def should_agent_terminate(self, agent: object, history: list[ChatMessageContent]) -> bool:
        """Check if the agent should terminate."""
        return "TERMINATE" in history[-1].content


async def get_answer(request: RequestModel) -> ResponseMessage:
    REVIEWERAGENT_INSTRUCTIONS = """
        You are a helpful assistant that ensures to review and summarize some information from
        WikiAgent, IssuesAgent and ImagesAgent, the information given from this Agents is context needed
        for response the User question.

        ### Rules
            - Format the information in MarkDown, use the emoji of a robot before the response.
            - Generate 3 sections, Response, Wiki References and Issues Related.
            - The Response MUST answer to the user question using images if they are in the WikiAgent retrieved data,
                DO NOT ADD the url references in this section.
            - Wiki References MUST Add the links to the wiki pages used for answer the user question,
                those links are provided by WikiAgent.
            - Issues Related MUST USE the information loaded from IssuesAgent, Add the links in this section,
                those links are provided by IssuesAgent.
            - MANDATORY TO ADD at the end of the message the word TERMINATE.
        """
    token_consumption_mgr = TokenConsumptionManager()
    agent_wiki_searcher = WikiAgent(
        wiki_urls=request.githubWikis, base_url_images=request.githubWikiBaseImageUrl
    ).build_agent()
    agent_reviewer = ReviewerAgent(REVIEWERAGENT_INSTRUCTIONS).build_agent()
    agent_issue_searcher = IssuesAgent(repo=request.githubRepo).build_agent()
    agent_images = ImagesAgent().build_agent()

    response = ResponseMessage()

    group_chat = AgentGroupChat(
        agents=[
            agent_images,
            agent_wiki_searcher,
            agent_issue_searcher,
            agent_reviewer,
        ],
        termination_strategy=ApprovalTerminationStrategy(
            agents=[agent_reviewer],
            maximum_iterations=10,
        ),
    )
    if config.ISDEVELOPMENT:
        logging.getLogger("kernel").setLevel(logging.DEBUG)
    response.add_user_message(request.question)
    await group_chat.add_chat_message(ChatMessageContent(role="user", content=request.question))
    logging.info(f"# User: {request.question}")
    async for content in group_chat.invoke():
        token_consumption_mgr.add_token_consumption(
            content.name,
            content.metadata["usage"].prompt_tokens,
            content.metadata["usage"].completion_tokens,
        )
        response.add_group_agent_message(content.name, content.content)
        logging.info(f"# {content.name} : {content.content}")

    answermessage = response.get_last_reviewed_message()
    response.historyMessages.append(answermessage)
    response.answer = answermessage.message
    response.completion_tokens = token_consumption_mgr.total_completion_tokens
    response.prompt_tokens = token_consumption_mgr.total_prompt_tokens
    return response


async def search_for_exceptions_and_report(request: ExceptionWatchRequestModel) -> ResponseMessage:
    token_consumption_mgr = TokenConsumptionManager()
    # We use some agents int this flow, exception agent search for exceptions,
    # issues agent search if there are issues already created,
    # if there is no issues the issues agent creates the issue and assigns to a github copilot coding agent to create a
    # PR and we need a workflow reviewer agent to review the results and show to user

    REVIEWERAGENT_INSTRUCTIONS = """
        You are a helpful assistant that ensures to review and summarize how the workflow from other agents has gone.
        There is 2 agents in the conversation, ExceptionsAgent and IssuesAgent:
        - ExceptionsAgent: Search for exceptions in the last 24 hours in the logAnalytics workspace. If an exception is
        found and can be solved coding a PR, this agent gives the exception details.
        - IssuesAgent: if we have an exception, we must create an issue with the exception details and assign to a
        developer to work and with the solution.

        Please collect all the information from the other agents and generate a summary of the workflow.
        """
    agent_exceptions = ExceptionsAgent(
        azure_tenant=request.azure_tenant_id,
        azure_client_id=request.azure_client_id,
        azure_client_secret=request.azure_client_secret,
        log_workspace_id=request.azure_log_analytics_workspace_id,
        days=request.days,
    ).build_agent()
    agent_reviewer = ReviewerAgent(REVIEWERAGENT_INSTRUCTIONS).build_agent()
    # agent_issue_searcher = IssuesAgent(repo=config.GITHUB_REPO).build_agent()
    agent_issue_creator = IssuesCreationAgent(repo=request.github_repo).build_agent()
    response = ResponseMessage()

    group_chat = AgentGroupChat(
        agents=[
            agent_exceptions,
            # agent_issue_searcher,
            agent_issue_creator,
            agent_reviewer,
        ],
        termination_strategy=ApprovalTerminationStrategy(
            agents=[agent_reviewer],
            maximum_iterations=10,
        ),
    )
    if config.ISDEVELOPMENT:
        logging.getLogger("kernel").setLevel(logging.DEBUG)
    prompt = "Search for exceptions in the last 24 hours and report them as issues if needed."
    response.add_user_message(prompt)
    await group_chat.add_chat_message(ChatMessageContent(role="user", content=prompt))
    logging.info(f"# User: {prompt}")
    async for content in group_chat.invoke():
        token_consumption_mgr.add_token_consumption(
            content.name,
            content.metadata["usage"].prompt_tokens,
            content.metadata["usage"].completion_tokens,
        )
        response.add_group_agent_message(content.name, content.content)
        logging.info(f"# {content.name} : {content.content}")

    answermessage = response.get_last_reviewed_message()
    response.historyMessages.append(answermessage)
    response.answer = answermessage.message
    response.completion_tokens = token_consumption_mgr.total_completion_tokens
    response.prompt_tokens = token_consumption_mgr.total_prompt_tokens
    return response
