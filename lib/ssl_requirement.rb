require "#{File.dirname(__FILE__)}/url_rewriter"

# Copyright (c) 2005 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module SslRequirement
  mattr_reader :ssl_host
  mattr_reader :ssl_protocol
  
  def self.ssl_host=(host)
    @@ssl_host = host
  end

  def self.ssl_protocol=(protocol)
    @@ssl_protocol = protocl
  end
  
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.before_filter(:ensure_proper_protocol)
  end

  def self.disable_ssl_check?
    @@disable_ssl_check ||= false
  end

  def self.disable_ssl_check=(value)
    @@disable_ssl_check = value
  end

  module ClassMethods
    # Specifies that the named actions requires an SSL connection to be performed (which is enforced by ensure_proper_protocol).
    def ssl_required(*actions)
      write_inheritable_array(:ssl_required_actions, actions)
    end

    def ssl_exceptions(*actions)
      write_inheritable_array(:ssl_required_except_actions, actions)
    end

    def ssl_allowed(*actions)
      write_inheritable_array(:ssl_allowed_actions, actions)
    end
  end

  protected
    # Returns true if the current action is supposed to run as SSL
    def ssl_required?
      required = (self.class.read_inheritable_attribute(:ssl_required_actions) || [])
      except  = self.class.read_inheritable_attribute(:ssl_required_except_actions)

      unless except
        required.include?(action_name.to_sym)
      else
        !except.include?(action_name.to_sym)
      end
    end

    def ssl_allowed?
      (self.class.read_inheritable_attribute(:ssl_allowed_actions) || []).include?(action_name.to_sym)
    end

  private
    def ensure_proper_protocol
      return true if SslRequirement.disable_ssl_check?
      return true if ssl_allowed?

      if ssl_required? && !request.ssl?
        redirect_to (ssl_protocol || "https") + "://" + (ssl_host || request.host) + request.request_uri
        flash.keep
        return false
      elsif request.ssl? && !ssl_required?
        redirect_to "http://" + request.host + request.request_uri
        flash.keep
        return false
      end
    end
end
