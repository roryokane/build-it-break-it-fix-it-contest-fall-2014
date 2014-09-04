module BIBIFI # Build It Break It Fix It
	class Error < StandardError; end
	
	class IntegrityViolationError < Error; end
	class SecurityError < Error; end
	class InvalidError < Error; end
end
