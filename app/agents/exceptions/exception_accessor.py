import logging
from datetime import datetime, timedelta, timezone

from azure.identity import ClientSecretCredential
from azure.monitor.query import LogsQueryClient


class ExceptionData:
    def __init__(self, message: str, stacktrace: str, count: int):
        self.message = message
        self.stacktrace = stacktrace
        self.count = count


class ExceptionAccessor:
    @staticmethod
    def get_exceptions_from_loganalytics(
        azure_tenant: str,
        azure_client_id: str,
        azure_client_secret: str,
        log_workspace_id: str,
        days: int,
    ) -> list[ExceptionData]:
        """
        Consulta excepciones agregadas desde Log Analytics usando credenciales de servicio.

        Parámetros:
            azure_tenant: ID (GUID) del tenant (Directory / Entra ID).
            azure_client_id: Client (application) ID de la app registrada.
            azure_client_secret: Client secret emitido para la app.
            log_workspace_id: Workspace ID (GUID) de Log Analytics.
            days: Rango de días hacia atrás a consultar.

        Retorna:
            Lista de ExceptionData con resumen de excepciones.
        """
        if days <= 0:
            days = 1

        KQL_QUERY = """
        AppExceptions
        | summarize
            Count = coalesce(sum(ItemCount), count()),
            ExceptionType = any(ExceptionType),
            OuterType = any(OuterType),
            Details = any(Details)
            by ProblemId
        | project ExceptionType, OuterType, Stacktrace = strcat(OuterType, ":", Details), Count
        | order by Count desc
        """

        # Autenticación explícita con credenciales de la firma
        try:
            credential = ClientSecretCredential(
                tenant_id=azure_tenant,
                client_id=azure_client_id,
                client_secret=azure_client_secret,
            )
        except Exception as ex:
            # Si hay error construyendo la credencial devolvemos vacío
            # (podrías lanzar excepción si prefieres fallo duro)
            logging.error(f"Error creando credencial de Azure: {ex}")
            return []

        client = LogsQueryClient(credential)

        end_time = datetime.now(timezone.utc)
        start_time = end_time - timedelta(days=days)
        timespan = (start_time, end_time)

        try:
            response = client.query_workspace(
                workspace_id=log_workspace_id,
                query=KQL_QUERY,
                timespan=timespan,
            )
        except Exception as ex:
            logging.error(f"Error consultando Log Analytics: {ex}")
            return []

        exceptions_summary: list[ExceptionData] = []
        if response.tables:
            table = response.tables[0]
            for row in table.rows:
                # row schema: [Type, Message, Stacktrace, Count]
                exc_type = row[0]
                exc_msg = row[1]
                stacktrace = row[2]
                count = row[3]
                # Puedes combinar Type + Message si lo deseas
                combined_msg = f"{exc_type}: {exc_msg}"
                exceptions_summary.append(ExceptionData(message=combined_msg, stacktrace=stacktrace, count=count))
        logging.info(f"Encontradas {len(exceptions_summary)} excepciones en Log Analytics.")
        logging.debug(f"Excepciones: {exceptions_summary}")
        return exceptions_summary
