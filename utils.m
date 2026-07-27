function varargout = utils(action, varargin)
%UTILS 工具函数集合
%   集中管理常用计算逻辑，减少代码重复
%   v1.1 新增：向量化辅助函数、缓存计算

persistent L_d_expanded protoC_cache

switch action
    case 'expand_L_d'
        % 展开方向距离向量 (所有个体共用)
        % 输入: L_d, traineachd
        % 输出: EXL_d (1 x J_max)
        L_d = varargin{1};
        traineachd = varargin{2};
        if isempty(L_d_expanded)
            L_d_expanded = [];
            for i = 1:length(L_d)
                L_d_expanded = [L_d_expanded, repmat(L_d(i), 1, traineachd(i))];
            end
        end
        varargout{1} = L_d_expanded;
        
    case 'clear_cache'
        % 清除持久变量缓存
        L_d_expanded = [];
        protoC_cache = [];
        
    case 'calc_C_JD'
        % 向量化计算每列班列的集装箱数量
        % 输入: y_ijdc (pop_size x C_max), J_max
        % 输出: C_JD (pop_size x J_max)
        y_ijdc = varargin{1};
        J_max = varargin{2};
        pop_size = size(y_ijdc, 1);
        C_JD = zeros(pop_size, J_max);
        for j = 1:J_max
            C_JD(:, j) = sum(y_ijdc == j, 2);
        end
        varargout{1} = C_JD;
        
    case 'calc_n_JD'
        % 计算所需车底数
        % 输入: C_JD
        % 输出: n_JD
        C_JD = varargin{1};
        varargout{1} = ceil(C_JD / 2);
        
    case 'calc_dir_flags'
        % 向量化计算直取标志
        % 输入: C_TJ, C_IDT_row4, mintranstime
        % 输出: z_ijdc
        C_TJ = varargin{1};
        C_IDT_ti = varargin{2};
        mintranstime = varargin{3};
        varargout{1} = double(C_IDT_ti + mintranstime >= C_TJ);
        
    case 'get_protoC_cache'
        % 获取protoC缓存
        if isempty(protoC_cache)
            protoC_cache.TI = [];
            protoC_cache.SUMI = [];
        end
        varargout{1} = protoC_cache;
        
    case 'set_protoC_cache'
        protoC_cache = varargin{1};
        
    otherwise
        error('Unknown action: %s', action);
end

end
