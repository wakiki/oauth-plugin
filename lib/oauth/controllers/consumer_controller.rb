module Oauth
  module Controllers
    module ConsumerController
      def self.included(controller)
        controller.class_eval do  
          before_filter :login_required
          before_filter :load_consumer, :except=>:index
          skip_before_filter :verify_authenticity_token,:only=>:callback
        end
      end
      
      def index
        @consumer_tokens=ConsumerToken.all :conditions=>{:person_id=>current_person.id}
        # The services the person hasn't already connected to
        @services=OAUTH_CREDENTIALS.keys-@consumer_tokens.collect{|c| c.class.service_name}
      end
      
      
      # creates request token and redirects on to oauth provider's auth page
      # If person is already connected it displays a page with an option to disconnect and redo
      def show
        unless @token
          @request_token = @consumer.get_request_token(callback_oauth_consumer_url(params[:id]))
          session[@request_token.token] = @request_token.secret
          if @request_token.callback_confirmed?
            redirect_to @request_token.authorize_url
          else
            redirect_to(@request_token.authorize_url + "&oauth_callback=#{callback_oauth_consumer_url(params[:id])}")
          end
        end
      end

      def callback
        @request_token_secret = session[ params[:oauth_token] ]
        if @request_token_secret
          begin
            session[ params[:oauth_token] ] = nil  # stops session getting full if multiple attempts
            @token = @consumer.create_from_request_token( current_person, params[:oauth_token], @request_token_secret, params[:oauth_verifier] )
            if @token
              flash[:notice] = "#{params[:id].humanize} was successfully connected to your account"
              go_back
            else
              flash[:error] = "An error happened, please try connecting again"
              redirect_to oauth_consumer_url(params[:id])
            end
          rescue OAuth::Unauthorized
            render :text => "Sorry, authorisation failed or declined. Close this window and try again."
          end            
        else
          flash[:error] = "Missing oauth session token"
          redirect_to blank_path
        end
      end

      def destroy
        throw RecordNotFound unless @token
        @token.destroy
        if params[:commit]=="Reconnect"
          redirect_to oauth_consumer_url(params[:id])
        else
          flash[:notice] = "#{params[:id].humanize} was successfully disconnected from your account"
          redirect_to oauth_consumers_path
        end
      end

      protected
      
      # Override this in your controller to decide where you want to redirect person to after callback is finished.
      def go_back
        redirect_to root_url
      end
      
      def load_consumer
        consumer_key=params[:id].to_sym
        throw RecordNotFound unless OAUTH_CREDENTIALS.include?(consumer_key)
        @consumer="#{consumer_key.to_s.camelcase}Token".constantize
        @token=@consumer.find_by_person_id current_person.id
      end
      
    end
  end
end