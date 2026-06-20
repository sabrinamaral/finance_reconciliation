class ClaudeAuditService
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"

  def initialize(unreconciled_records, unreconciled_records2)
    @unreconciled1 = unreconciled_records
    @unreconciled2 = unreconciled_records2
  end

  def call
    return { success: false, error: "Nenhum lançamento pendente para analisar." } if @unreconciled1.empty? && @unreconciled2.empty?

    response = Faraday.post(ANTHROPIC_API_URL) do |req|
      req.headers["x-api-key"]         = ENV["ANTHROPIC_API_KEY"]
      req.headers["anthropic-version"]  = "2023-06-01"
      req.headers["content-type"]       = "application/json"
      req.body = build_payload.to_json
    end

    if response.success?
      body = JSON.parse(response.body)
      { success: true, analysis: body.dig("content", 0, "text") }
    else
      { success: false, error: "Erro na API do Claude: #{response.status}" }
    end
  end

  private

  def build_payload
    {
      model: "claude-sonnet-4-6",
      max_tokens: 2048,
      messages: [
        { role: "user", content: build_prompt }
      ]
    }
  end

  def build_prompt
    <<~PROMPT
      Você é um auditor financeiro especializado em conciliação bancária para imobiliárias.

      Abaixo estão os lançamentos que NÃO foram conciliados automaticamente entre o extrato bancário e o sistema da imobiliária.

      ## Lançamentos no extrato bancário SEM correspondência no sistema:
      #{format_records(@unreconciled1)}

      ## Lançamentos no sistema SEM correspondência no extrato bancário:
      #{format_records(@unreconciled2)}

      Por favor, analise esses lançamentos e:
      1. Identifique possíveis correspondências com datas próximas ou valores similares
      2. Aponte lançamentos suspeitos ou que merecem atenção
      3. Indique possíveis causas para cada divergência (atraso de compensação, tarifa bancária, erro de lançamento, etc.)
      4. Sugira ações para cada caso

      Responda em português, de forma estruturada e objetiva.
    PROMPT
  end

  def format_records(records)
    return "Nenhum lançamento pendente." if records.empty?

    records.map do |r|
      "- Data: #{r.date} | Valor: R$ #{r.amount} | Descrição: #{r.description.presence || 'sem descrição'}"
    end.join("\n")
  end
end
