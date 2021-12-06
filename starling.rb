# (C)2021 Kjartan Rex

require 'restclient'
require 'json'
require 'yaml'

Token= YAML.load_file(File.join Dir.home, '.starling')[:token]

class Starling
  BASE_URL='https://api.starlingbank.com/api/v2/'
  
  def initialize token
    @header= {Authorization:"Bearer #{token}"}
  end
  
  def get url, params={}
    response= RestClient.get "#{BASE_URL}#{url}", @header.merge(params: params)
    JSON.parse response, symbolize_names: true    
  end
  
  def put url, data, params={}
    r= RestClient.put "#{BASE_URL}#{url}", data.to_json, @header.merge(content_type: :json).merge(params: params)
    ((200..299)===r.code) && (r.length>0 && (JSON.parse response, symbolize_names: true)|| true)
  end
  
  def accounts
    raw= get 'accounts'
    @accounts= raw[:accounts].map{|x| Account.new self, x}
  end
  
  def cards
    (get "cards")[:cards].map{|x| Card.new self, x}    
  end
  
  def accountHolder
    case (x= get "account-holder")[:accountHolderType]
    when "INDIVIDUAL"
      individual
    when "BUSINESS"
      business
    when "SOLE_TRADER"
      soleTrader
    when "JOINT"
      joint
    when "BANKING_AS_A_SERVICE"
     bankingAAS
    else
      x
    end    
  end
  
  def individual
    Individual.new self, (get 'account-holder/individual')
  end
  
  class Individual
    attr_reader :title, :firstName, :lastName, :dob, :email, :phone
    def initialize parent, title:, firstName:, lastName:, dateOfBirth:, email:, phone:
      @parent, @title, @firstName, @lastName, @dateOfBirth, @email, @phone= parent, title, firstName, lastName, dateOfBirth, email, phone
    end
    
    def email= e
      put '/api/v2/account-holder/individual/email', {email: e}.to_json      
    end
    
    def inspect
      "#<Individual #{[firstName, lastName].join ' '}>"
    end
  end
  
  class Card
    attr_reader :uid, :publicToken, :enabled, :walletNotificationEnabled, :posEnabled, :atmEnabled, :onlineEnabled, :mobileWalletEnabled, :gamblingEnabled, :magStripeEnabled, :cancelled, :activationRequested, :activated, :endOfCardNumber, :currencyFlags, :cardAssociationUid
    def initialize parent, cardUid:, publicToken:, enabled:, walletNotificationEnabled:, posEnabled:, atmEnabled:, onlineEnabled:, mobileWalletEnabled:, gamblingEnabled:, magStripeEnabled:, cancelled:, activationRequested:, activated:, endOfCardNumber:, currencyFlags:, cardAssociationUid:
      @parent, @uid, @publicToken, @enabled, @walletNotificationEnabled, @posEnabled, @atmEnabled, @onlineEnabled, @mobileWalletEnabled, @gamblingEnabled, @magStripeEnabled, @cancelled, @activationRequested, @activated, @endOfCardNumber, @currencyFlags, @cardAssociationUid= parent, cardUid, publicToken, enabled, walletNotificationEnabled, posEnabled, atmEnabled, onlineEnabled, mobileWalletEnabled, gamblingEnabled, magStripeEnabled, cancelled, activationRequested, activated, endOfCardNumber, currencyFlags, cardAssociationUid
    end
    def inspect      
      "#<Card …#{endOfCardNumber}>"
    end
  end
    
  class Account
    attr_reader :uid, :type, :name
    def initialize parent, accountUid:, accountType:, defaultCategory:, currency:, createdAt:, name:
      @parent= parent
      @name= name
      @uid= accountUid
      @type= accountType
      @defaultCategory= defaultCategory
      @currency= currency.to_sym
      @created= Time.parse createdAt
    end    
    
    def parent
      @parent
    end
        
    def balance
      raw= parent.get "/api/v2/accounts/#{@uid}/balance"
      raw.map{|k,v| [k, {currency: v[:currency].to_sym, value: v[:minorUnits]}]}      
    end
    
    def inspect
      "#<Account #{@name}>"
    end
  end
end

JointAccount= Starling.new Token[:joint]