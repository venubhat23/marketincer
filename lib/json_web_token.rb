# app/lib/json_web_token.rb
class JsonWebToken
  SECRET_KEY = "2c6a000c287b677ea5d15d696109d582d461c5a70a2cdee29e717bf5f4446eb10fb7cb2bc9378f6688de67c678699512df4fd074f469acc01236c5d03e768656"

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new decoded
  rescue JWT::DecodeError
    nil
  end
end